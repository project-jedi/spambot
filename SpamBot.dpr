program SpamBot;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Math,
  Classes,
  DateUtils,
  MediaWikiUtils in 'MediaWikiUtils.pas',
  MediaWikiApi in 'MediaWikiApi.pas';

function CheckUserPage(MediaWikiApi: TMediaWikiApi; const Namespace, UserName: string; out Title: string): Boolean;
var
  PageInfos: TMediaWikiPageInfos;
  PageRevisionInfos: TMediaWikiPageRevisionInfos;
  ContinueInfo: TMediaWikiContinueInfo;
  Hours: Integer;
begin
  Result := False;

  Title := Namespace + ':' + UserName;

  MediaWikiApi.QueryPageInfo(Title, False, [mwfIncludeProtection], PageInfos);
  if Length(PageInfos) <> 1 then
    Exit;

  if PageInfos[0].PageBasics.PageID = -1 then
    Exit;

  if not (mwfPageIsNew in PageInfos[0].PageFlags) then
    Exit;

  ContinueInfo.ParameterName := '';
  ContinueInfo.ParameterValue := '';
  MediaWikiApi.QueryPageRevisionInfo(Title, False, [mwfIncludeRevisionAuthor, mwfIncludeRevisionTimeStamp], PageRevisionInfos, ContinueInfo);
  if Length(PageRevisionInfos) <> 1 then
    Exit;

  Hours := HoursBetween(Now, PageRevisionInfos[0].PageRevisionInfoDateTime);
  if (PageRevisionInfos[0].PageRevisionInfoAuthor = UserName) and
     (Hours >= 1) and (Hours <= 48) then
    Result := True;
end;

procedure CheckUser(MediaWikiApi: TMediaWikiApi; const UserNamespace, UserTalkNamespace: string; const UserInfo: TMediaWikiAllUserInfo);
var
  Merge, DeleteUserPage, DeleteUserTalkPage: Boolean;
  I, Hours: Integer;
  UserMergeInfo: TMediaWikiUserMergeInfo;
  UserPageTitle, UserTalkPageTitle: string;
  DeleteInfo: TMediaWikiDeleteInfo;
  TokenValues: TMediaWikiTokenValues;
begin
  DeleteUserPage := False;
  DeleteUserTalkPage := False;
  UserPageTitle := '';
  UserTalkPageTitle := '';

  WriteLn(UserInfo.UserName);
  WriteLn('  created on ', DateTimeToStrISO8601(UserInfo.UserRegistration));
  WriteLn('  edit count = ', UserInfo.UserEditCount);
  WriteLn('  groups = ');
  for I := Low(UserInfo.UserGroups) to High(UserInfo.UserGroups) do
    WriteLn('    ', UserInfo.UserGroups[I]);

  Hours := HoursBetween(Now, UserInfo.UserRegistration);
  Merge := (Hours >= 12) and (Hours <= 24) and (UserInfo.UserEditCount = 0);

  if not Merge then
  begin
    DeleteUserPage := CheckUserPage(MediaWikiApi, UserNamespace, UserInfo.UserName, UserPageTitle);
    DeleteUserTalkPage := CheckUserPage(MediaWikiApi, UserTalkNamespace, UserInfo.UserName, UserTalkPageTitle);
    Merge := (DeleteUserPage and (not DeleteUserTalkPage) and (UserInfo.UserEditCount = 1)) or
             ((not DeleteUserPage) and DeleteUserTalkPage and (UserInfo.UserEditCount = 1)) or
             (DeleteUserPage and DeleteUserTalkPage and (UserInfo.UserEditCount = 2));
  end;

  Merge := Merge and (Length(UserInfo.UserGroups) <= 3);

  if Merge then
  begin
    WriteLn('  delete user page');
    if DeleteUserPage then
    begin
      MediaWikiApi.QueryTokens([mwtCsrf], TokenValues);
      MediaWikiApi.Delete(UserPageTitle, TokenValues[mwtCsrf], 'spam', 0, DeleteInfo, True);
      if DeleteInfo.DeleteSuccess then
        WriteLn('    success')
      else
        WriteLn('    failure');
    end
    else
      WriteLn('    skip');

    WriteLn('  delete user talk page');
    if DeleteUserTalkPage then
    begin
      MediaWikiApi.QueryTokens([mwtCsrf], TokenValues);
      MediaWikiApi.Delete(UserTalkPageTitle, TokenValues[mwtCsrf], 'spam', 0, DeleteInfo, True);
      if DeleteInfo.DeleteSuccess then
        WriteLn('    success')
      else
        WriteLn('    failure');
    end
    else
      WriteLn('    skip');

    WriteLn('  merge');
    MediaWikiApi.QueryTokens([mwtCsrf], TokenValues);
    MediaWikiApi.UserMerge(UserInfo.UserName, 'Spam', TokenValues[mwtCsrf], True, UserMergeInfo);
    if UserMergeInfo.UserMergeSuccess then
      WriteLn('    success')
    else
      WriteLn('    failure');
  end
  else
  begin
    WriteLn('  skip');
    Exit;
  end;
end;

procedure QueryAllUsers(MediaWikiApi: TMediaWikiApi; const UserNamespace, UserTalkNamespace: string);
var
  AllUserInfos: TMediaWikiAllUserInfos;
  ContinueInfo: TMediaWikiContinueInfo;
  I: Integer;
begin
  repeat
    MediaWikiApi.QueryAllUserInfo(AllUserInfos, ContinueInfo, '', '', 10, [mwfIncludeUserEditCount, mwfIncludeUserRegistration, mwfIncludeUserGroups]);
    for I := Low(AllUserInfos) to High(AllUserInfos) do
      CheckUser(MediaWikiApi, UserNamespace, UserTalkNamespace, AllUserInfos[I]);
  until (ContinueInfo.ParameterValue = '');
end;

procedure QueryNamespaces(MediaWikiApi: TMediaWikiApi; out UserNamespace, UserTalkNamespace: string);
var
  Namespaces: TStrings;
  I: Integer;
begin
  Namespaces := TStringList.Create;
  try
    UserNamespace := '';
    UserTalkNamespace := '';
    MediaWikiApi.QuerySiteInfoNamespaces(Namespaces);
    for I := 0 to Namespaces.Count - 1 do
    begin
      case StrToInt(Namespaces.ValueFromIndex[I]) of
        2: // NS_USER
          UserNamespace := Namespaces.Names[I];
        3: // NS_USER_TALK
          UserTalkNamespace := Namespaces.Names[I];
      end;
    end;
  finally
    Namespaces.Free;
  end;
end;

procedure QueryUserInfo(MediaWikiApi: TMediaWikiApi);
var
  Infos: TStrings;
  I: Integer;
begin
  Infos := TStringList.Create;
  try
    WriteLn('User Block Info :');
    MediaWikiApi.QueryUserInfoBlockInfo(Infos);
    for I := 0 to Infos.Count - 1 do
      WriteLn('  ' + Infos.Strings[I]);
    WriteLn('User Groups :');
    MediaWikiApi.QueryUserInfoGroups(Infos);
    for I := 0 to Infos.Count - 1 do
      WriteLn('  ' + Infos.Strings[I]);
    WriteLn('User Rights :');
    MediaWikiApi.QueryUserInfoRights(Infos);
    for I := 0 to Infos.Count - 1 do
      WriteLn('  ' + Infos.Strings[I]);
  finally
    Infos.Free;
  end;
end;

procedure PrintWarning(Sender: TMediaWikiApi; const AInfo, AQuery: string; var Ignore: Boolean);
begin
  WriteLn('Warning during query "' + AQuery + '" :');
  WriteLn('  ' + AInfo);
end;

procedure Execute;
var
  MediaWikiApi: TMediaWikiApi;
  UserNamespace, UserTalkNamespace: string;
begin
  MediaWikiApi := TMediaWikiApi.Create;
  try
    MediaWikiApi.HttpsCli.URL := '';
    MediaWikiApi.HttpsCli.Agent := '';
    MediaWikiApi.HttpsCli.FollowRelocation := False;
    MediaWikiApi.OnWarning := PrintWarning;
    MediaWikiApi.LoginUserName := '';
    MediaWikiApi.LoginPassword := '';
    if MediaWikiApi.Login = mwlSuccess then
    begin
      try
        QueryUserInfo(MediaWikiApi);
        QueryNamespaces(MediaWikiApi, UserNamespace, UserTalkNamespace);
        QueryAllUsers(MediaWikiApi, UserNamespace, UserTalkNamespace);
      finally
        MediaWikiApi.Logout;
      end;
    end;
  finally
    MediaWikiApi.Free;
  end;
end;

begin
  try
    Execute;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
