{**************************************************************************************************}
{                                                                                                  }
{ Project JEDI                                                                                     }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is MediaWikiApi.pas                                                            }
{                                                                                                  }
{ The Initial Developer of the Original Code is Florent Ouchet.                                    }
{ Portions created by Florent Ouchet are Copyright Florent Ouchet. All rights reserved.            }
{                                                                                                  }
{ Contributor(s):                                                                                  }
{                                                                                                  }
{**************************************************************************************************}

unit MediaWikiApi;

interface

// main documentation is located at http://www.mediawiki.org/wiki/API

uses
  SysUtils,
  Classes,
  JclBase,
  JclSimpleXml,
  OverbyteIcsHttpProt,
  OverbyteIcsWSocket,
  MediaWikiUtils;

type
  TMediaWikiRequest = (mwrLogin, mwrLogout,
                       mwrQuerySiteInfoGeneral, mwrQuerySiteInfoNamespaces, mwrQuerySiteInfoNamespaceAliases,
                       mwrQuerySiteInfoSpecialPageAliases, mwrQuerySiteInfoMagicWords, mwrQuerySiteInfoStatistics,
                       mwrQuerySiteInfoInterWikiMap, mwrQuerySiteInfoDBReplLag, mwrQuerySiteInfoUserGroups,
                       mwrQuerySiteInfoExtensions,
                       mwrQueryTokens,
                       mwrQueryUserInfoBlockInfo, mwrQueryUserInfoHasMsg, mwrQueryUserInfoGroups,
                       mwrQueryUserInfoRights, mwrQueryUserInfoChangeableGroups, mwrQueryUserInfoOptions,
                       mwrQueryUserInfoEditCount, mwrQueryUserInfoRateLimits,
                       mwrQueryMessages,
                       mwrQueryPageInfo, mwrQueryPageRevisionInfo, mwrQueryPageCategoryInfo,
                       mwrQueryPageLinkInfo, mwrQueryPageTemplateInfo, mwrQueryPageExtLinkInfo,
                       mwrQueryAllPageInfo, mwrQueryAllLinkInfo, mwrQueryAllCategoryInfo,
                       mwrQueryAllUserInfo, mwrQueryBackLinkInfo, mwrQueryBlockInfo, mwrQueryCategoryMemberInfo,
                       mwrEdit, mwrMove, mwrDelete, mwrDeleteRevision, mwrUpload, mwrUserMerge);

  TMediaWikiRequests = set of TMediaWikiRequest;

const
  MediaWikiExclusiveRequests: TMediaWikiRequests =
    [mwrLogin, mwrLogout, mwrEdit, mwrMove, mwrDelete, mwrDeleteRevision, mwrUpload];

{$TYPEINFO ON}

type
  TMediaWikiApi = class;

  TMediaWikiCallback = procedure (Sender: TMediaWikiApi) of object;
  TMediaWikiWarningCallback = procedure (Sender: TMediaWikiApi; const AInfo, AQuery: string; var Ignore: Boolean);
  TMediaWikiErrorCallback = procedure (Sender: TMediaWikiApi; const AInfo, ACode: string; var Ignore: Boolean);
  TMediaWikiXMLCallback = procedure (Sender: TMediaWikiApi; XML: TJclSimpleXML) of object;
  TMediaWikiStringsCallback = procedure (Sender: TMediaWikiApi; AStrings: TStrings) of object;
  TMediaWikiExtensionsCallback = procedure (Sender: TMediaWikiApi; const Extensions: TMediaWikiExtensions) of object;
  TMediaWikiBooleanCallback = procedure (Sender: TMediaWikiApi; Value: Boolean) of object;
  TMediaWikiIntegerCallback = procedure (Sender: TMediaWikiApi; Value: Integer) of object;
  TMediaWikiRateLimitsCallback = procedure (Sender: TMediaWikiApi; const RateLimits: TMediaWikiRateLimits) of object;
  TMediaWikiPageInfosCallback = procedure (Sender: TMediaWikiApi; const PageInfos: TMediaWikiPageInfos) of object;
  TMediaWikiPageRevisionInfosCallback = procedure (Sender: TMediaWikiApi; const PageRevisionInfos: TMediaWikiPageRevisionInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiRevisionRangeCallback = procedure (Sender: TMediaWikiApi; StartRevID, EndRevID: TMediaWikiID) of object;
  TMediaWikiPageCategoryCallback = procedure (Sender: TMediaWikiApi; const PageCategoryInfos: TMediaWikiPageCategoryInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiPageLinkCallback = procedure (Sender: TMediaWikiApi; const PageLinkInfos: TMediaWikiPageLinkInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiPageTemplateCallback = procedure (Sender: TMediaWikiApi; const PageTemplateInfos: TMediaWikiPageTemplateInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiPageExtLinkCallback = procedure (Sender: TMediaWikiApi; const PageExtLinkInfos: TMediaWikiPageExtLinkInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiAllPageCallback = procedure (Sender: TMediaWikiApi; const AllPages: TMediaWikiAllPageInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiAllLinkCallback = procedure (Sender: TMediaWikiApi; const AllLinks: TMediaWikiAllLinkInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiAllCategoriesCallback = procedure (Sender: TMediaWikiApi; ACategories: TStrings; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiAllUserCallback = procedure (Sender: TMediaWikiApi; const AllUsers: TMediaWikiAllUserInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiBackLinkCallback = procedure (Sender: TMediaWikiApi; const BackLinks: TMediaWikiBackLinkInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiBlockCallback = procedure (Sender: TMediaWikiApi; const Blocks: TMediaWikiBlockInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiCategoryMemberCallback = procedure (Sender: TMediaWikiApi; const CategoryMembers: TMediaWikiCategoryMemberInfos; const ContinueInfo: TMediaWikiContinueInfo) of object;
  TMediaWikiEditCallback = procedure (Sender: TMediaWikiApi; const EditInfo: TMediaWikiEditInfo) of object;
  TMediaWikiMoveCallback = procedure (Sender: TMediaWikiApi; const MoveInfo: TMediaWikiMoveInfo) of object;
  TMediaWikiDeleteCallback = procedure (Sender: TMediaWikiApi; const DeleteInfo: TMediaWikiDeleteInfo) of object;
  TMediaWikiDeleteRevisionCallback = procedure (Sender: TMediaWikiApi; const DeleteRevisionInfo: TMediaWikiDeleteRevisionInfo) of object;
  TMediaWikiUploadCallback = procedure (Sender: TMediaWikiApi; const UploadInfo: TMediaWikiUploadInfo) of object;
  TMediaWikiUserMergeCallback = procedure (Sender: TMediaWikiApi; const UserMergeInfo: TMediaWikiUserMergeInfo) of object;
  TMediaWikiTokenValuesCallback = procedure (Sender: TMediaWikiApi; const Tokens: TMediaWikiTokenValues) of object;

  TMediaWikiXMLRequestCallbacks = array [TMediaWikiRequest] of TMediaWikiXMLCallback;

  TMediaWikiApi = class
  // general stuff
  private
    FHttpsCli: TSslHttpCli;
    FSslContext: TSslContext;
    procedure OnCookieRcvd(Sender: TObject; const Data: String; var Accept: Boolean);
  private
    FSendStream: TMemoryStream;
    FReceiveStream: TMemoryStream;
    FRequestCallbacks: TMediaWikiXMLRequestCallbacks;
    FQueryStrings: TStrings;
    FPendingRequests: TMediaWikiRequests;
    function GetReady: Boolean;
    procedure RequestDone(Sender: TObject; RqType: THttpRequest; ErrCode: Word);
  public
    constructor Create;
    destructor Destroy; override;
    procedure CheckRequest(Request: TMediaWikiRequest);

    procedure QueryInit;
    property SendStream: TMemoryStream read FSendStream;
    property ReceiveStream: TMemoryStream read FReceiveStream;
    // synchronous post
    function QueryExecute: AnsiString;
    procedure QueryExecuteXML(XML: TJclSimpleXML);
    // asynchronous post
    procedure QueryExecuteAsync;

    property PendingRequests: TMediaWikiRequests read FPendingRequests;
    property Ready: Boolean read GetReady;
  published
    property HttpsCli: TSslHttpCli read FHttpsCli;
    property SslContext: TSslContext read FSslContext;
  // error handling
  private
    FIgnoreWarnings: Boolean;
    FIgnoreErrors: Boolean;
    FOnWarning: TMediaWikiWarningCallback;
    FOnError: TMediaWikiErrorCallback;
    procedure ProcessXMLWarning(const AInfo, AQuery: string);
    procedure ProcessXMLError(const AInfo, ACode: string);
  public
    property IgnoreWarnings: Boolean read FIgnoreWarnings write FIgnoreWarnings;
    property IgnoreErrors: Boolean read FIgnoreErrors write FIgnoreErrors;
    property OnWarning: TMediaWikiWarningCallback read FOnWarning write FOnWarning;
    property OnError: TMediaWikiErrorCallback read FOnError write FOnError;
    //property OutputFormat: TMediaWikiOutputFormat;
  // login stuff
  private
    FOnLoginDone: TMediaWikiCallback;
    FLoginPassword: string;
    FLoginResult: TMediaWikiLoginResult;
    FLoginToken: string;
    FLoginUserID: TMediaWikiID;
    FLoginUserName: string;
    procedure LoginParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
    procedure LoginGetToken(Sender: TMediaWikiApi; const TokenValues: TMediaWikiTokenValues);
  public
    // synchronous login
    function Login: TMediaWikiLoginResult; overload;
    function Login(const lgName, lgPassword: string): TMediaWikiLoginResult; overload;
    function Login(const lgName, lgPassword, lgToken: string): TMediaWikiLoginResult; overload;
    function Login(const lgName, lgPassword, lgToken: string; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    // asynchronous login
    procedure LoginAsync; overload;
    procedure LoginAsync(const lgName, lgPassword: string); overload;
    procedure LoginAsync(const lgName, lgPassword, lgToken: string); overload;
    property OnLoginDone: TMediaWikiCallback read FOnLoginDone write FOnLoginDone;
    // login states
    property LoginToken: string read FLoginToken write FLoginToken;
    property LoginResult: TMediaWikiLoginResult read FLoginResult write FLoginResult;
    property LoginUserID: TMediaWikiID read FLoginUserID write FLoginUserID;
  published
    property LoginUserName: string read FLoginUserName write FLoginUserName;
    property LoginPassword: string read FLoginPassword write FLoginPassword;
  // logout stuff
  private
    FOnLogoutDone: TMediaWikiCallback;
    procedure LogoutParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    // synchronous login
    procedure Logout; overload;
    procedure Logout(const csrf: string); overload;
    // asynchronous login
    procedure LogoutAsync(const csrf: string);
    property OnLogoutDone: TMediaWikiCallback read FOnLogoutDone write FOnLogoutDone;
  // Meta information queries, site information, general
  private
    FOnQuerySiteInfoGeneralDone: TMediaWikiStringsCallback;
    FQuerySiteInfoGeneralStrings: TStrings;
    procedure QuerySiteInfoGeneralParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoGeneral(Infos: TStrings); overload;
    function QuerySiteInfoGeneral(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoGeneralAsync;
    property OnQuerySiteInfoGeneralDone: TMediaWikiStringsCallback read FOnQuerySiteInfoGeneralDone write FOnQuerySiteInfoGeneralDone;
  // Meta information queries, site information, namespaces: A list of all namespaces
  private
    FOnQuerySiteInfoNamespacesDone: TMediaWikiStringsCallback;
    FQuerySiteInfoNamespacesStrings: TStrings;
    procedure QuerySiteInfoNamespacesParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoNamespaces(Infos: TStrings); overload;
    function QuerySiteInfoNamespaces(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoNamespacesAsync;
    property OnQuerySiteInfoNamespacesDone: TMediaWikiStringsCallback read FOnQuerySiteInfoNamespacesDone write FOnQuerySiteInfoNamespacesDone;
  // Meta information queries, site information, namespacealiases: A list of all namespace aliases (MW 1.13+)
  private
    FOnQuerySiteInfoNamespaceAliasesDone: TMediaWikiStringsCallback;
    FQuerySiteInfoNamespaceAliasesStrings: TStrings;
    procedure QuerySiteInfoNamespaceAliasesParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoNamespaceAliases(Infos: TStrings); overload;
    function QuerySiteInfoNamespaceAliases(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoNamespaceAliasesAsync;
    property OnQuerySiteInfoNamespaceAliasesDone: TMediaWikiStringsCallback read FOnQuerySiteInfoNamespaceAliasesDone write FOnQuerySiteInfoNamespaceAliasesDone;
  // Meta information queries, site information, specialpagealiases: A list of all special page aliases (MW 1.13+)
  private
    FOnQuerySiteInfoSpecialPageAliasesDone: TMediaWikiStringsCallback;
    FQuerySiteInfoSpecialPageAliasesStrings: TStrings;
    procedure QuerySiteInfoSpecialPageAliasesParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoSpecialPageAliases(Infos: TStrings); overload;
    function QuerySiteInfoSpecialPageAliases(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoSpecialPageAliasesAsync;
    property OnQuerySiteInfoSpecialPageAliasesDone: TMediaWikiStringsCallback read FOnQuerySiteInfoSpecialPageAliasesDone write FOnQuerySiteInfoSpecialPageAliasesDone;
  // Meta information queries, site information, magicwords: A list of magic words and their aliases (MW 1.14+)
  private
    FOnQuerySiteInfoMagicWordsDone: TMediaWikiStringsCallback;
    FQuerySiteInfoMagicWordsStrings: TStrings;
    procedure QuerySiteInfoMagicWordsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoMagicWords(Infos: TStrings); overload;
    function QuerySiteInfoMagicWords(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoMagicWordsAsync;
    property OnQuerySiteInfoMagicWordsDone: TMediaWikiStringsCallback read FOnQuerySiteInfoMagicWordsDone write FOnQuerySiteInfoMagicWordsDone;
  // Meta information queries, site information, statistics: Site statistics � la Special:Statistics (MW 1.11+)
  private
    FOnQuerySiteInfoStatisticsDone: TMediaWikiStringsCallback;
    FQuerySiteInfoStatisticsStrings: TStrings;
    procedure QuerySiteInfoStatisticsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoStatistics(Infos: TStrings); overload;
    function QuerySiteInfoStatistics(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoStatisticsAsync;
    property OnQuerySiteInfoStatisticsDone: TMediaWikiStringsCallback read FOnQuerySiteInfoStatisticsDone write FOnQuerySiteInfoStatisticsDone;
  // Meta information queries, site information, interwikimap: A list of all interwiki prefixes and where they go (MW 1.11+)
  private
    FOnQuerySiteInfoInterWikiMapDone: TMediaWikiStringsCallback;
    FQuerySiteInfoInterWikiMapStrings: TStrings;
    procedure QuerySiteInfoInterWikiMapParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoInterWikiMap(Local: Boolean; Infos: TStrings); overload;
    function QuerySiteInfoInterWikiMap(Local: Boolean; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoInterWikiMapAsync(Local: Boolean);
    property OnQuerySiteInfoInterWikiMapDone: TMediaWikiStringsCallback read FOnQuerySiteInfoInterWikiMapDone write FOnQuerySiteInfoInterWikiMapDone;
  // Meta information queries, site information, dbrepllag: Get information about the database server with the highest replication lag (MW 1.11)
  private
    FOnQuerySiteInfoDBReplLagDone: TMediaWikiStringsCallback;
    FQuerySiteInfoDBReplLagStrings: TStrings;
    procedure QuerySiteInfoDBReplLagParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoDBReplLag(ShowAllDB: Boolean; Infos: TStrings); overload;
    function QuerySiteInfoDBReplLag(ShowAllDB: Boolean; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoDBReplLagAsync(ShowAllDB: Boolean);
    property OnQuerySiteInfoDBReplLagDone: TMediaWikiStringsCallback read FOnQuerySiteInfoDBReplLagDone write FOnQuerySiteInfoDBReplLagDone;
  // Meta information queries, site information, usergroups: A list of all user groups and their permissions (MW 1.13+)
  private
    FOnQuerySiteInfoUserGroupsDone: TMediaWikiStringsCallback;
    FQuerySiteInfoUserGroupsStrings: TStrings;
    procedure QuerySiteInfoUserGroupsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoUserGroups(IncludeUserCount: Boolean; Infos: TStrings); overload;
    function QuerySiteInfoUserGroups(IncludeUserCount: Boolean; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoUserGroupsAsync(IncludeUserCount: Boolean);
    property OnQuerySiteInfoUserGroupsDone: TMediaWikiStringsCallback read FOnQuerySiteInfoUserGroupsDone write FOnQuerySiteInfoUserGroupsDone;
  // Meta information queries, site information, extensions: A list of extensions installed on the wiki (MW 1.14+)
  private
    FOnQuerySiteInfoExtensionsDone: TMediaWikiExtensionsCallback;
    FQuerySiteInfoExtensions: TMediaWikiExtensions;
    procedure QuerySiteInfoExtensionsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QuerySiteInfoExtensions(out Infos: TMediaWikiExtensions); overload;
    function QuerySiteInfoExtensions(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QuerySiteInfoExtensionsAsync;
    property OnQuerySiteInfoExtensionsDone: TMediaWikiExtensionsCallback read FOnQuerySiteInfoExtensionsDone write FOnQuerySiteInfoExtensionsDone;
    (* TODO: fileextensions: A list of file extensions allowed to be uploaded (MW 1.15+) *)
    (* TODO: rightsinfo: Get information about the license governing the wiki's content (MW 1.15+) *)
    (* TODO: languages: Get available languages as seen in preferences (MW 1.16+) *)

  // Meta information queries, tokens
  private
    FOnQueryTokensDone: TMediaWikiTokenValuesCallback;
    FQueryTokenValues: TMediaWikiTokenValues;
    procedure QueryTokensParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryTokens(Tokens: TMediaWikiTokens; out TokenValues: TMediaWikiTokenValues); overload;
    function QueryTokens(Tokens: TMediaWikiTokens; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryTokensAsync(Tokens: TMediaWikiTokens);
    property OnQueryTokenDone: TMediaWikiTokenValuesCallback read FOnQueryTokensDone write FOnQueryTokensDone;
    property QueryTokenValues: TMediaWikiTokenValues read FQueryTokenValues write FQueryTokenValues;
  // Meta information queries, user information, blockinfo: Whether the current user is blocked, by whom, and why
  private
    FOnQueryUserInfoBlockInfoDone: TMediaWikiStringsCallback;
    FQueryUserInfoBlockInfoStrings: TStrings;
    procedure QueryUserInfoBlockInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoBlockInfo(Infos: TStrings); overload;
    function QueryUserInfoBlockInfo(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoBlockInfoAsync;
    property OnQueryUserInfoBlockInfoDone: TMediaWikiStringsCallback read FOnQueryUserInfoBlockInfoDone write FOnQueryUserInfoBlockInfoDone;
  // Meta information queries, user information, hasmsg: Whether the current user has new messages on their user talk page
  private
    FOnQueryUserInfoHasMsgDone: TMediaWikiBooleanCallback;
    FQueryUserInfoHasMsg: Boolean;
    procedure QueryUserInfoHasMsgParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    function QueryUserInfoHasMsg: Boolean; overload;
    function QueryUserInfoHasMsg(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoHasMsgAsync;
    property OnQueryUserInfoHasMsgDone: TMediaWikiBooleanCallback read FOnQueryUserInfoHasMsgDone write FOnQueryUserInfoHasMsgDone;
  // Meta information queries, user information, groups: Which groups the current user belongs to
  private
    FOnQueryUserInfoGroupsDone: TMediaWikiStringsCallback;
    FQueryUserInfoGroupsStrings: TStrings;
    procedure QueryUserInfoGroupsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoGroups(Infos: TStrings); overload;
    function QueryUserInfoGroups(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoGroupsAsync;
    property OnQueryUserInfoGroupsDone: TMediaWikiStringsCallback read FOnQueryUserInfoGroupsDone write FOnQueryUserInfoGroupsDone;
  // Meta information queries, user information, rights: Which rights the current user has
  private
    FOnQueryUserInfoRightsDone: TMediaWikiStringsCallback;
    FQueryUserInfoRightsStrings: TStrings;
    procedure QueryUserInfoRightsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoRights(Infos: TStrings); overload;
    function QueryUserInfoRights(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoRightsAsync;
    property OnQueryUserInfoRightsDone: TMediaWikiStringsCallback read FOnQueryUserInfoRightsDone write FOnQueryUserInfoRightsDone;
  // Meta information queries, user information, changeablegroups: Which groups the current user can add/remove
  private
    FOnQueryUserInfoChangeableGroupsDone: TMediaWikiStringsCallback;
    FQueryUserInfoChangeableGroupsStrings: TStrings;
    procedure QueryUserInfoChangeableGroupsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoChangeableGroups(Infos: TStrings); overload;
    function QueryUserInfoChangeableGroups(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoChangeableGroupsAsync;
    property OnQueryUserInfoChangeableGroupsDone: TMediaWikiStringsCallback read FOnQueryUserInfoChangeableGroupsDone write FOnQueryUserInfoChangeableGroupsDone;
  // Meta information queries, user information, options: Which preferences the current user has
  private
    FOnQueryUserInfoOptionsDone: TMediaWikiStringsCallback;
    FQueryUserInfoOptionsStrings: TStrings;
    procedure QueryUserInfoOptionsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoOptions(Infos: TStrings); overload;
    function QueryUserInfoOptions(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoOptionsAsync;
    property OnQueryUserInfoOptionsDone: TMediaWikiStringsCallback read FOnQueryUserInfoOptionsDone write FOnQueryUserInfoOptionsDone;
  // Meta information queries, user information, editcount: The number of edits the current user has made
  private
    FOnQueryUserInfoEditCountDone: TMediaWikiIntegerCallback;
    FQueryUserInfoEditCount: Integer;
    procedure QueryUserInfoEditCountParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    function QueryUserInfoEditCount: Integer; overload;
    function QueryUserInfoEditCount(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoEditCountAsync;
    property OnQueryUserInfoEditCountDone: TMediaWikiIntegerCallback read FOnQueryUserInfoEditCountDone write FOnQueryUserInfoEditCountDone;
  // Meta information queries, user information, ratelimits: Rate limits applying to the current user
  private
    FOnQueryUserInfoRateLimitsDone: TMediaWikiRateLimitsCallback;
    FQueryUserInfoRateLimits: TMediaWikiRateLimits;
    procedure QueryUserInfoRateLimitsParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryUserInfoRateLimits(out Infos: TMediaWikiRateLimits); overload;
    function QueryUserInfoRateLimits(OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryUserInfoRateLimitsAsync;
    property OnQueryUserInfoRateLimitsDone: TMediaWikiRateLimitsCallback read FOnQueryUserInfoRateLimitsDone write FOnQueryUserInfoRateLimitsDone;
    (* TODO: email: Email address and authentication timestamp in ISO 8601 format [1.15+] *)

  // Meta information queries, allmessages: Lists the contents of all (or a few) interface messages.
  private
    FOnQueryMessagesDone: TMediaWikiStringsCallback;
    FQueryMessagesStrings: TStrings;
    procedure QueryMessagesParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryMessages(const NameFilter, ContentFilter, Lang: string; Infos: TStrings); overload;
    function QueryMessages(const NameFilter, ContentFilter, Lang: string; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryMessagesAsync(const NameFilter, ContentFilter, Lang: string);
    property OnQueryMessagesDone: TMediaWikiStringsCallback read FOnQueryMessagesDone write FOnQueryMessagesDone;

  // Queries, info / in: Gets basic page information
  private
    FOnQueryPageInfoDone: TMediaWikiPageInfosCallback;
    FQueryPageInfos: TMediaWikiPageInfos;
    procedure QueryPageInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageInfoFlags; out Infos: TMediaWikiPageInfos); overload;
    function QueryPageInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageInfoFlags; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure QueryPageInfoAsync(const Titles: string; PageID: Boolean; Flags: TMediaWikiPageInfoFlags);
    property OnQueryPageInfoDone: TMediaWikiPageInfosCallback read FOnQueryPageInfoDone write FOnQueryPageInfoDone;

  // Queries, revisions / rv: Returns revisions for a given page
  private
    FOnQueryPageRevisionInfoDone: TMediaWikiPageRevisionInfosCallback;
    FQueryPageRevisionInfos: TMediaWikiPageRevisionInfos;
    FQueryPageRevisionContinueInfo: TMediaWikiContinueInfo;
    procedure QueryPageRevisionInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageRevisionInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageRevisionInfoFlags; out Infos: TMediaWikiPageRevisionInfos;
      var ContinueInfo: TMediaWikiContinueInfo;
      MaxRevisions: Integer = 0; Section: Integer = -1; StartRevisionID: TMediaWikiID = -1;
      EndRevisionID: TMediaWikiID = -1; const StartDateTime: TDateTime = 0.0;
      const EndDateTime: TDateTime = 0.0; const IncludeUser: string = '';
      const ExcludeUser: string = ''); overload;
    function QueryPageRevisionInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageRevisionInfoFlags; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo;
      MaxRevisions: Integer = 0; Section: Integer = -1; StartRevisionID: TMediaWikiID = -1;
      EndRevisionID: TMediaWikiID = -1; const StartDateTime: TDateTime = 0.0;
      const EndDateTime: TDateTime = 0.0; const IncludeUser: string = '';
      const ExcludeUser: string = ''): AnsiString; overload;
    procedure QueryPageRevisionInfoAsync(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageRevisionInfoFlags; const ContinueInfo: TMediaWikiContinueInfo;
      MaxRevisions: Integer = 0;
      Section: Integer = -1; StartRevisionID: TMediaWikiID = -1;
      EndRevisionID: TMediaWikiID = -1; const StartDateTime: TDateTime = 0.0;
      const EndDateTime: TDateTime = 0.0; const IncludeUser: string = '';
      const ExcludeUser: string = '');
    property OnQueryPageRevisionInfoDone: TMediaWikiPageRevisionInfosCallback read FOnQueryPageRevisionInfoDone write FOnQueryPageRevisionInfoDone;

  // Queries, categories / cl: Gets a list of all categories
  private
    FOnQueryPageCategoryInfoDone: TMediaWikiPageCategoryCallback;
    FQueryPageCategoryInfos: TMediaWikiPageCategoryInfos;
    FQueryPageCategoryContinueInfo: TMediaWikiContinueInfo;
    procedure QueryPageCategoryInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageCategoryInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageCategoryInfoFlags; out Infos: TMediaWikiPageCategoryInfos;
      var ContinueInfo: TMediaWikiContinueInfo;
      MaxCategories: Integer = 0; const CategoryTitles: string = ''); overload;
    function QueryPageCategoryInfo(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageCategoryInfoFlags; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo;
      MaxCategories: Integer = 0; const CategoryTitles: string = ''): AnsiString; overload;
    procedure QueryPageCategoryInfoAsync(const Titles: string; PageID: Boolean;
      Flags: TMediaWikiPageCategoryInfoFlags; const ContinueInfo: TMediaWikiContinueInfo;
      MaxCategories: Integer = 0; const CategoryTitles: string = '');
    property OnQueryPageCategoryInfoDone: TMediaWikiPageCategoryCallback read FOnQueryPageCategoryInfoDone write FOnQueryPageCategoryInfoDone;

  // Queries, imageinfo / ii: Gets image information TODO

  // Queries, langlinks / ll: Gets a list of all language links TODO

  // Queries, links / pl: Gets a list of all links
  private
    FOnQueryPageLinkInfoDone: TMediaWikiPageLinkCallback;
    FQueryPageLinkInfos: TMediaWikiPageLinkInfos;
    FQueryPageLinkContinueInfo: TMediaWikiContinueInfo;
    procedure QueryPageLinkInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageLinkInfo(const Titles: string; PageID: Boolean; out Infos: TMediaWikiPageLinkInfos;
      var ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0; Namespace: Integer = -1); overload;
    function QueryPageLinkInfo(const Titles: string; PageID: Boolean; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0; Namespace: Integer = -1): AnsiString; overload;
    procedure QueryPageLinkInfoAsync(const Titles: string; PageID: Boolean;
      const ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0; Namespace: Integer = -1);
    property OnQueryPageLinkInfoDone: TMediaWikiPageLinkCallback read FOnQueryPageLinkInfoDone write FOnQueryPageLinkInfoDone;

  // Queries, templates / tl: Gets a list of all pages included in the provided pages
  private
    FOnQueryPageTemplateInfoDone: TMediaWikiPageTemplateCallback;
    FQueryPageTemplateInfos: TMediaWikiPageTemplateInfos;
    FQueryPageTemplateContinueInfo: TMediaWikiContinueInfo;
    procedure QueryPageTemplateInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageTemplateInfo(const Titles: string; PageID: Boolean; out Infos: TMediaWikiPageTemplateInfos;
      var ContinueInfo: TMediaWikiContinueInfo; MaxTemplates: Integer = 0; Namespace: Integer = -1); overload;
    function QueryPageTemplateInfo(const Titles: string; PageID: Boolean; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo; MaxTemplates: Integer = 0; Namespace: Integer = -1): AnsiString; overload;
    procedure QueryPageTemplateInfoAsync(const Titles: string; PageID: Boolean;
      const ContinueInfo: TMediaWikiContinueInfo; MaxTemplates: Integer = 0; Namespace: Integer = -1);
    property OnQueryPageTemplateInfoDone: TMediaWikiPageTemplateCallback read FOnQueryPageTemplateInfoDone write FOnQueryPageTemplateInfoDone;

  // Queries, images / im: Gets a list of all images used on the provided pages TODO

  // Queries, extlinks / el: Gets a list of all external links on the provided pages
  private
    FOnQueryPageExtLinkInfoDone: TMediaWikiPageExtLinkCallback;
    FQueryPageExtLinkInfos: TMediaWikiPageExtLinkInfos;
    FQueryPageExtLinkContinueInfo: TMediaWikiContinueInfo;
    procedure QueryPageExtLinkInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryPageExtLinkInfo(const Titles: string; PageID: Boolean; out Infos: TMediaWikiPageExtLinkInfos;
      var ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0); overload;
    function QueryPageExtLinkInfo(const Titles: string; PageID: Boolean; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0): AnsiString; overload;
    procedure QueryPageExtLinkInfoAsync(const Titles: string; PageID: Boolean;
      const ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer = 0);
    property OnQueryPageExtLinkInfoDone: TMediaWikiPageExtLinkCallback read FOnQueryPageExtLinkInfoDone write FOnQueryPageExtLinkInfoDone;

  // Queries, categoryinfo / ci: Gets information about categories TODO

  // Queries, duplicatefiles / df: List duplicates of the given files. TODO


  // Queries, list, all pages: Returns a list of pages in a given namespace, ordered by page title.
  private
    FOnQueryAllPageInfoDone: TMediaWikiAllPageCallback;
    FQueryAllPageInfos: TMediaWikiAllPageInfos;
    FQueryAllPageContinueInfo: TMediaWikiContinueInfo;
    procedure QueryAllPageInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryAllPageInfo(out Infos: TMediaWikiAllPageInfos; var ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxPage: Integer = 0; Namespace: Integer = -1;
      RedirFilter: TMediaWikiAllPageFilterRedir = mwfAllPageFilterAll;
      LangFilter: TMediaWikiAllPageFilterLang = mwfAllPageLangAll; MinSize: Integer = -1; MaxSize: Integer = -1;
      ProtectionFilter: TMediaWikiAllPageFilterProtection = mwfAllPageProtectionNone;
      LevelFilter: TMediaWikiAllPageFilterLevel = mwfAllPageLevelNone;
      Direction: TMediaWikiAllPageDirection = mwfAllPageAscending); overload;
    function QueryAllPageInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxPage: Integer = 0; Namespace: Integer = -1;
      RedirFilter: TMediaWikiAllPageFilterRedir = mwfAllPageFilterAll;
      LangFilter: TMediaWikiAllPageFilterLang = mwfAllPageLangAll; MinSize: Integer = -1; MaxSize: Integer = -1;
      ProtectionFilter: TMediaWikiAllPageFilterProtection = mwfAllPageProtectionNone;
      LevelFilter: TMediaWikiAllPageFilterLevel = mwfAllPageLevelNone;
      Direction: TMediaWikiAllPageDirection = mwfAllPageAscending): AnsiString; overload;
    procedure QueryAllPageInfoAsync(const ContinueInfo: TMediaWikiContinueInfo; const Prefix: string = ''; MaxPage: Integer = 0;
      Namespace: Integer = -1; RedirFilter: TMediaWikiAllPageFilterRedir = mwfAllPageFilterAll;
      LangFilter: TMediaWikiAllPageFilterLang = mwfAllPageLangAll; MinSize: Integer = -1; MaxSize: Integer = -1;
      ProtectionFilter: TMediaWikiAllPageFilterProtection = mwfAllPageProtectionNone;
      LevelFilter: TMediaWikiAllPageFilterLevel = mwfAllPageLevelNone;
      Direction: TMediaWikiAllPageDirection = mwfAllPageAscending);
    property OnQueryAllPageInfoDone: TMediaWikiAllPageCallback read FOnQueryAllPageInfoDone write FOnQueryAllPageInfoDone;

  // Queries, list, all links: Returns a list of (unique) links to pages in a given namespace starting ordered by link title.
  private
    FOnQueryAllLinkInfoDone: TMediaWikiAllLinkCallback;
    FQueryAllLinkInfos: TMediaWikiAllLinkInfos;
    FQueryAllLinkContinueInfo: TMediaWikiContinueInfo;
    procedure QueryAllLinkInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryAllLinkInfo(out Infos: TMediaWikiAllLinkInfos; var ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxLink: Integer = 0; Namespace: Integer = -1;
      Flags: TMediaWikiAllLinkInfoFlags = []); overload;
    function QueryAllLinkInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxLink: Integer = 0; Namespace: Integer = -1;
      Flags: TMediaWikiAllLinkInfoFlags = []): AnsiString; overload;
    procedure QueryAllLinkInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxLink: Integer = 0; Namespace: Integer = -1;
      Flags: TMediaWikiAllLinkInfoFlags = []);
    property OnQueryAllLinkInfoDone: TMediaWikiAllLinkCallback read FOnQueryAllLinkInfoDone write FOnQueryAllLinkInfoDone;

  // Queries, list, all categories: Get a list of all categories.
  private
    FOnQueryAllCategoryInfoDone: TMediaWikiAllCategoriesCallback;
    FQueryAllCategoryInfos: TStrings;
    FQueryAllCategoryContinueInfo: TMediaWikiContinueInfo;
    procedure QueryAllCategoryInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryAllCategoryInfo(Infos: TStrings; var ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxCategory: Integer = 0; Flags: TMediaWikiAllCategoryInfoFlags = []); overload;
    function QueryAllCategoryInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxCategory: Integer = 0; Flags: TMediaWikiAllCategoryInfoFlags = []): AnsiString; overload;
    procedure QueryAllCategoryInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; MaxCategory: Integer = 0; Flags: TMediaWikiAllCategoryInfoFlags = []);
    property OnQueryAllCategoryInfoDone: TMediaWikiAllCategoriesCallback read FOnQueryAllCategoryInfoDone write FOnQueryAllCategoryInfoDone;

  // Queries, list, all users: Get a list of registered users, ordered by username.
  private
    FOnQueryAllUserInfoDone: TMediaWikiAllUserCallback;
    FQueryAllUserInfos: TMediaWikiAllUserInfos;
    FQueryAllUserContinueInfo: TMediaWikiContinueInfo;
    procedure QueryAllUserInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryAllUserInfo(out Infos: TMediaWikiAllUserInfos; var ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; const Group: string = ''; MaxUser: Integer = 0;
      Flags: TMediaWikiAllUserInfoFlags = []); overload;
    function QueryAllUserInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; const Group: string = ''; MaxUser: Integer = 0;
      Flags: TMediaWikiAllUserInfoFlags = []): AnsiString; overload;
    procedure QueryAllUserInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
      const Prefix: string = ''; const Group: string = ''; MaxUser: Integer = 0;
      Flags: TMediaWikiAllUserInfoFlags = []);
    property OnQueryAllUserInfoDone: TMediaWikiAllUserCallback read FOnQueryAllUserInfoDone write FOnQueryAllUserInfoDone;

  // Queries, list, allimages / ai: Returns a list of all images, ordered by image title. TODO

  // Queries, list, all backlinks / bl: Lists pages that link to a given page, similar to Special:Whatlinkshere. Ordered by linking page title.
  private
    FOnQueryBackLinkInfoDone: TMediaWikiBackLinkCallback;
    FQueryBackLinkInfos: TMediaWikiBackLinkInfos;
    FQueryBackLinkContinueInfo: TMediaWikiContinueInfo;
    procedure QueryBackLinkInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryBackLinkInfo(const BackLinkTitle: string; out Infos: TMediaWikiBackLinkInfos;
      var ContinueInfo: TMediaWikiContinueInfo; Namespace: Integer = -1; MaxLink: Integer = 0;
      Flags: TMediaWikiBackLinkInfoFlags = []); overload;
    function QueryBackLinkInfo(const BackLinkTitle: string; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo; Namespace: Integer = -1; MaxLink: Integer = 0;
      Flags: TMediaWikiBackLinkInfoFlags = []): AnsiString; overload;
    procedure QueryBackLinkInfoAsync(const BackLinkTitle: string;
      const ContinueInfo: TMediaWikiContinueInfo; Namespace: Integer = -1; MaxLink: Integer = 0;
      Flags: TMediaWikiBackLinkInfoFlags = []);
    property OnQueryBackLinkInfoDone: TMediaWikiBackLinkCallback read FOnQueryBackLinkInfoDone write FOnQueryBackLinkInfoDone;

  // Queries, list, all blocks / bk: List all blocks, � la Special:Ipblocklist. This module cannot be used as a generator.
  private
    FOnQueryBlockInfoDone: TMediaWikiBlockCallback;
    FQueryBlockInfos: TMediaWikiBlockInfos;
    FQueryBlockContinueInfo: TMediaWikiContinueInfo;
    procedure QueryBlockInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryBlockInfo(out Infos: TMediaWikiBlockInfos; var ContinueInfo: TMediaWikiContinueInfo;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const BlockIDs: string = ''; const Users: string = ''; const IP: string = ''; MaxBlock: Integer = 0;
      Flags: TMediaWikiBlockInfoFlags = []); overload;
    function QueryBlockInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const BlockIDs: string = ''; const Users: string = ''; const IP: string = ''; MaxBlock: Integer = 0;
      Flags: TMediaWikiBlockInfoFlags = []): AnsiString; overload;
    procedure QueryBlockInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const BlockIDs: string = ''; const Users: string = ''; const IP: string = ''; MaxBlock: Integer = 0;
      Flags: TMediaWikiBlockInfoFlags = []);
    property OnQueryBlockInfoDone: TMediaWikiBlockCallback read FOnQueryBlockInfoDone write FOnQueryBlockInfoDone;

  // Queries, list, categorymembers / cm: List of pages that belong to a given category, ordered by page sort title.
  private
    FOnQueryCategoryMemberInfoDone: TMediaWikiCategoryMemberCallback;
    FQueryCategoryMemberInfos: TMediaWikiCategoryMemberInfos;
    FQueryCategoryMemberContinueInfo: TMediaWikiContinueInfo;
    procedure QueryCategoryMemberInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure QueryCategoryMemberInfo(const CategoryTitle: string; out Infos: TMediaWikiCategoryMemberInfos;
      var ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer = -1;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const StartSortKey: string = ''; const StopSortKey: string = ''; MaxCategoryMember: Integer = 0;
      Flags: TMediaWikiCategoryMemberInfoFlags = []); overload;
    function QueryCategoryMemberInfo(const CategoryTitle: string; OutputFormat: TMediaWikiOutputFormat;
      const ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer = -1;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const StartSortKey: string = ''; const StopSortKey: string = ''; MaxCategoryMember: Integer = 0;
      Flags: TMediaWikiCategoryMemberInfoFlags = []): AnsiString; overload;
    procedure QueryCategoryMemberInfoAsync(const CategoryTitle: string;
      const ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer = -1;
      const StartDateTime: TDateTime = 0.0; const StopDateTime: TDateTime = 0.0;
      const StartSortKey: string = ''; const StopSortKey: string = ''; MaxCategoryMember: Integer = 0;
      Flags: TMediaWikiCategoryMemberInfoFlags = []);
    property OnQueryCategoryMemberInfoDone: TMediaWikiCategoryMemberCallback read FOnQueryCategoryMemberInfoDone write FOnQueryCategoryMemberInfoDone;

  // Queries, list, embeddedin / ei: List pages that include a certain page TODO

  // Queries, list, exturlusage / eu: Get a list of pages that link to a certain URL, � la Special:Linksearch TODO

  // Queries, list, imageusage / iu: List of pages that include a given image. Ordered by page title. TODO

  // Queries, list, logevents / le: Get a list of all logged events, � la Special:Log. This module cannot be used as a generator. TODO

  // Queries, list, recentchanges / rc: Get all recent changes to the wiki, � la Special:Recentchanges. This module cannot be used as a generator. TODO

  // Queries, list, search / sr: Search for a string in all articles � la Special:Search TODO

  // Queries, list, usercontribs / uc: Gets a list of contributions made by a given user, ordered by modification time. This module cannot be used as a generator. TODO

  // Queries, list, watchlist / wl: Get a list of pages on the current user's watchlist that were changed within the given time period. Ordered by time of the last change of the watched page. TODO

  // Queries, list, deletedrevs / dr: List deleted revisions. TODO

  // Queries, list, users / us: Get information about a list of users. TODO

  // Queries, list, random / rn: Get a list of random pages. TODO

  // Queries, list, protectedtitles / pt: Get a list of titles protected from creation. TODO

  // Edit
  private
    FOnEditDone: TMediaWikiEditCallback;
    FEditInfo: TMediaWikiEditInfo;
    procedure EditParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure Edit(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary: string;
      out EditInfo: TMediaWikiEditInfo;
      const MD5: string = ''; const CaptchaID: string = ''; const CaptchaWord: string = '';
      const BaseDateTime: TDateTime = 0.0; const StartDateTime: TDateTime = 0.0;
      UndoRevisionID: TMediaWikiID = -1; Flags: TMediaWikiEditFlags = []); overload;
    function Edit(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary: string;
      OutputFormat: TMediaWikiOutputFormat;
      const MD5: string = ''; const CaptchaID: string = ''; const CaptchaWord: string = '';
      const BaseDateTime: TDateTime = 0.0; const StartDateTime: TDateTime = 0.0;
      UndoRevisionID: TMediaWikiID = -1; Flags: TMediaWikiEditFlags = []): AnsiString; overload;
    procedure EditAsync(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary: string;
      const MD5: string = ''; const CaptchaID: string = ''; const CaptchaWord: string = '';
      const BaseDateTime: TDateTime = 0.0; const StartDateTime: TDateTime = 0.0;
      UndoRevisionID: TMediaWikiID = -1; Flags: TMediaWikiEditFlags = []);
    property OnEditDone: TMediaWikiEditCallback read FOnEditDone write FOnEditDone;

  // Move
  private
    FOnMoveDone: TMediaWikiMoveCallback;
    FMoveInfo: TMediaWikiMoveInfo;
    procedure MoveParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure Move(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
      FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags; out MoveInfo: TMediaWikiMoveInfo); overload;
    function Move(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
      FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure MoveAsync(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
      FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags);
    property OnMoveDone: TMediaWikiMoveCallback read FOnMoveDone write FOnMoveDone;

  // Rollback TODO

  // Delete
  private
    FOnDeleteDone: TMediaWikiDeleteCallback;
    FDeleteInfo: TMediaWikiDeleteInfo;
    procedure DeleteParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure Delete(const PageTitle, DeleteToken, Reason: string;
      FromPageID: TMediaWikiID; out DeleteInfo: TMediaWikiDeleteInfo;
      Suppress: Boolean = False); overload;
    function Delete(const PageTitle, DeleteToken, Reason: string;
      FromPageID: TMediaWikiID; OutputFormat: TMediaWikiOutputFormat;
      Suppress: Boolean = False): AnsiString; overload;
    procedure DeleteAsync(const PageTitle, DeleteToken, Reason: string;
      FromPageID: TMediaWikiID; Suppress: Boolean = False);
    property OnDeleteDone: TMediaWikiDeleteCallback read FOnDeleteDone write FOnDeleteDone;

  // Delete Revision
  private
    FOnDeleteRevisionDone: TMediaWikiDeleteRevisionCallback;
    FDeleteRevisionInfo: TMediaWikiDeleteRevisionInfo;
    procedure DeleteRevisionParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure DeleteRevision(const PageTitle, DeleteToken, Reason: string;
      FromPageID, RevisionID: TMediaWikiID; out DeleteRevisionInfo: TMediaWikiDeleteRevisionInfo); overload;
    function DeleteRevision(const PageTitle, DeleteToken, Reason: string;
      FromPageID, RevisionID: TMediaWikiID; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure DeleteRevisionAsync(const PageTitle, DeleteToken, Reason: string;
      FromPageID, RevisionID: TMediaWikiID);
    property OnDeleteRevisionDone: TMediaWikiDeleteRevisionCallback read FOnDeleteRevisionDone write FOnDeleteRevisionDone;

  // restore deleted revisions TODO

  // (un)protect pages TODO

  // (Un)block users TODO

  // (Un)watch pages TODO

  // Send e-mail TODO

  // Patrol changes TODO

  // Import pages TODO

  // Change user group membership TODO

  // Upload files TODO
  private
    FOnUploadDone: TMediaWikiUploadCallback;
    FUploadInfo: TMediaWikiUploadInfo;
    procedure UploadParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure Upload(const FileName, Comment, Text, EditToken: string;
      Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string;
      out UploadInfo: TMediaWikiUploadInfo); overload;
    function Upload(const FileName, Comment, Text, EditToken: string;
      Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string;
      OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure UploadAsync(const FileName, Comment, Text, EditToken: string;
      Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string);
    property OnUploadDone: TMediaWikiUploadCallback read FOnUploadDone write FOnUploadDone;

  // User Merge
  private
    FOnUserMergeDone: TMediaWikiUserMergeCallback;
    FUserMergeInfo: TMediaWikiUserMergeInfo;
    procedure UserMergeParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
  public
    procedure UserMerge(const OldUser, NewUser, Token: string;
      DeleteUser: Boolean; out UserMergeInfo: TMediaWikiUserMergeInfo); overload;
    function UserMerge(const OldUser, NewUser, Token: string;
      DeleteUser: Boolean; OutputFormat: TMediaWikiOutputFormat): AnsiString; overload;
    procedure UserMergeAsync(const OldUser, NewUser, Token: string;
      DeleteUser: Boolean);
    property OnUserMergeDone: TMediaWikiUserMergeCallback read FOnUserMergeDone write FOnUserMergeDone;
  end;

{$TYPEINFO OFF}

implementation

uses
  JclStrings,
  JclStreams;

//=== { TMediaWikiApi } ======================================================

constructor TMediaWikiApi.Create;
begin
  inherited Create;
  FIgnoreWarnings := True;
  FIgnoreErrors := False;
  FHttpsCli := TSslHttpCli.Create(nil);
  FHttpsCli.OnRequestDone := RequestDone;
  FHttpsCli.OnCookie := OnCookieRcvd;
  FSslContext := TSslContext.Create(nil);
  FHttpsCli.SslContext := FSslContext;
  FSendStream := TMemoryStream.Create;
  FReceiveStream := TMemoryStream.Create;
  FHttpsCli.SendStream := FSendStream;
  FHttpsCli.RcvdStream := FReceiveStream;
  FQueryStrings := TStringList.Create;
end;

destructor TMediaWikiApi.Destroy;
begin
  if LoginUserID <> 0 then
    Logout;
  FQueryStrings.Free;
  FSendStream.Free;
  FReceiveStream.Free;
  FHttpsCli.Free;
  inherited Destroy;
end;

procedure TMediaWikiApi.OnCookieRcvd(Sender: TObject; const Data: String;
  var Accept: Boolean);
var
  Cookies: TStrings;
  Cookie, Name, Value: string;
begin
  Cookies := TStringList.Create;
  try
    StrToStrings(FHttpsCli.Cookie, '; ', Cookies);
    Cookie := StrBefore(';',Data);
    Name := StrBefore('=', Cookie);
    Value := StrAfter('=', Cookie);
    Cookies.Values[Name] := Value;
    FHttpsCli.Cookie := StringsToStr(Cookies,'; ', False);
  finally
    Cookies.Free;
  end;
  Accept := True;
end;

procedure TMediaWikiApi.CheckRequest(Request: TMediaWikiRequest);
begin
  // check socket ready state, done by httpcli

  if FPendingRequests * MediaWikiExclusiveRequests <> [] then
    raise EMediaWikiError.Create('execute exclusive request first', '');

  Include(FPendingRequests, Request);  
end;

function TMediaWikiApi.GetReady: Boolean;
begin
  Result := HttpsCli.State = httpReady;
end;

procedure TMediaWikiApi.ProcessXMLError(const AInfo, ACode: string);
var
  Ignore: Boolean;
begin
  Ignore := IgnoreErrors;
  if Assigned(FOnError) then
    FOnError(Self, AInfo, ACode, Ignore);
  if not Ignore then
    raise EMediaWikiError.Create(AInfo, ACode);
end;

procedure TMediaWikiApi.ProcessXMLWarning(const AInfo, AQuery: string);
var
  Ignore: Boolean;
begin
  Ignore := IgnoreWarnings;
  if Assigned(FOnWarning) then
    FOnWarning(Self, AInfo, AQuery, Ignore);
  if not Ignore then
    raise EMediaWikiWarning.Create(AInfo, AQuery);
end;

function TMediaWikiApi.QueryExecute: AnsiString;
var
  ContentType: string;
begin
  FSendStream.Size := 0;
  MediaWikiQueryPost(FQueryStrings, FSendStream, ContentType);
  FHttpsCli.ContentTypePost := ContentType;

  FSendStream.Position := 0;
  FReceiveStream.Size := 0;

  FHttpsCli.Post;
  FPendingRequests := [];

  SetLength(Result, FReceiveStream.Size);
  FReceiveStream.Position := 0;
  FReceiveStream.ReadBuffer(Result[1], Length(Result));
end;

procedure TMediaWikiApi.QueryExecuteAsync;
var
  ContentType: AnsiString;
begin
  FSendStream.Size := 0;
  MediaWikiQueryPost(FQueryStrings, FSendStream, ContentType);
  FHttpsCli.ContentTypePost := ContentType;

  FSendStream.Position := 0;
  FReceiveStream.Size := 0;

  FHttpsCli.PostASync;
end;

procedure TMediaWikiApi.QueryExecuteXML(XML: TJclSimpleXML);
var
  ContentType: string;
begin
  FSendStream.Size := 0;
  MediaWikiQueryPost(FQueryStrings, FSendStream, ContentType);
  FHttpsCli.ContentTypePost := ContentType;
  FSendStream.Position := 0;
  FReceiveStream.Size := 0;

  FHttpsCli.Post;
  FPendingRequests := [];

  FReceiveStream.Position := 0;
  try
    XML.LoadFromStream(FReceiveStream, seUTF8);
  except
    FReceiveStream.Position := 0;
//    FReceiveStream.SaveToFile('c:\dev\receive.xml');
    raise;
  end;

  MediaWikiCheckXML(XML, ProcessXMLWarning, ProcessXMLError);
end;

function TMediaWikiApi.Login(const lgName, lgPassword, lgToken: string;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrLogin);
  MediaWikiQueryLoginAdd(FQueryStrings, lgName, lgPassword, lgToken, OutputFormat);
  Result := QueryExecute;
end;

function TMediaWikiApi.Login: TMediaWikiLoginResult;
begin
  Result := Login(LoginUserName, LoginPassword);
end;

function TMediaWikiApi.Login(const lgName, lgPassword: string): TMediaWikiLoginResult;
var
  Tokens: TMediaWikiTokenValues;
begin
  QueryTokens([mwtLogin],Tokens);
  FLoginToken := Tokens[mwtLogin];
  Result := Login(lgName, lgPassword, FLoginToken);
end;

function TMediaWikiApi.Login(const lgName, lgPassword,
  lgToken: string): TMediaWikiLoginResult;
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrLogin);
    MediaWikiQueryLoginAdd(FQueryStrings, lgName, lgPassword, lgToken, mwoXML);
    QueryExecuteXml(XML);
    LoginParseXmlResult(Self, XML);
    Result := LoginResult;
  finally
    XML.Free;
  end;
end;

procedure TMediaWikiApi.LoginAsync;
begin
  OnQueryTokenDone := LoginGetToken;
  FRequestCallbacks[mwrLogin] := LoginParseXmlResult;
  CheckRequest(mwrLogin);
  QueryTokensAsync([mwtLogin]);
end;

procedure TMediaWikiApi.LoginAsync(const lgName, lgPassword: string);
begin
  FLoginUserName := lgName;
  FLoginPassword := lgPassword;
  LoginAsync;
end;

procedure TMediaWikiApi.LoginAsync(const lgName, lgPassword, lgToken: string);
begin
  FRequestCallbacks[mwrLogin] := LoginParseXmlResult;
  CheckRequest(mwrLogin);
  MediaWikiQueryLoginAdd(FQueryStrings, lgName, lgPassword, lgToken, mwoXML);
end;

procedure TMediaWikiApi.LoginGetToken(Sender: TMediaWikiApi; const TokenValues: TMediaWikiTokenValues);
begin
  FLoginToken := TokenValues[mwtLogin];
  LoginAsync(FLoginUserName, FLoginPassword, FLoginToken);
end;

procedure TMediaWikiApi.LoginParseXmlResult(Sender: TMediaWikiApi;
  XML: TJclSimpleXML);
begin
  MediaWikiQueryLoginParseXmlResult(XML, FLoginResult, FLoginUserID, FLoginUserName);

  if Assigned(FOnLoginDone) then
    FOnLoginDone(Self);
end;

procedure TMediaWikiApi.Logout;
var
  TokenValues: TMediaWikiTokenValues;
begin
  QueryTokens([mwtCsrf],TokenValues);
  Logout(TokenValues[mwtCsrf]);
end;

procedure TMediaWikiApi.Logout(const csrf: string);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrLogout);
    MediaWikiQueryLogoutAdd(FQueryStrings, csrf, mwoXML);
    QueryExecuteXML(XML);
    LogoutParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

procedure TMediaWikiApi.LogoutAsync(const csrf: string);
begin
  FRequestCallbacks[mwrLogout] := LogoutParseXmlResult;
  CheckRequest(mwrLogout);
  MediaWikiQueryLogoutAdd(FQueryStrings, csrf, mwoXML);
end;

procedure TMediaWikiApi.LogoutParseXmlResult(Sender: TMediaWikiApi;
  XML: TJclSimpleXML);
begin
  MediaWikiQueryLogoutParseXmlResult(XML);

  LoginUserID := 0;

  if Assigned(FOnLogoutDone) then
    FOnLogoutDone(Self);
end;

procedure TMediaWikiApi.QueryInit;
var
  Request: TMediaWikiRequest;
begin
  FQueryStrings.Clear;
  for Request := mwrQuerySiteInfoGeneral to High(TMediaWikiRequest) do
    FRequestCallbacks[Request] := nil;
  FPendingRequests := [];
end;

procedure TMediaWikiApi.QuerySiteInfoGeneral(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoGeneralStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoGeneral);
    MediaWikiQuerySiteInfoGeneralAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoGeneralParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoGeneral(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoGeneral);
  MediaWikiQuerySiteInfoGeneralAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoGeneralAsync;
begin
  CheckRequest(mwrQuerySiteInfoGeneral);
  MediaWikiQuerySiteInfoGeneralAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoGeneral] := QuerySiteInfoGeneralParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoGeneralParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoGeneralStrings);
  if OwnsStrings then
    FQuerySiteInfoGeneralStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoGeneralParseXmlResult(XML, FQuerySiteInfoGeneralStrings);

    if Assigned(FOnQuerySiteInfoGeneralDone) then
      FOnQuerySiteInfoGeneralDone(Self, FQuerySiteInfoGeneralStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoGeneralStrings)
    else
      FQuerySiteInfoGeneralStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespaces(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoNamespacesStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoNamespaces);
    MediaWikiQuerySiteInfoNamespacesAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoNamespacesParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoNamespaces(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoNamespaces);
  MediaWikiQuerySiteInfoNamespacesAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespacesAsync;
begin
  CheckRequest(mwrQuerySiteInfoNamespaces);
  MediaWikiQuerySiteInfoNamespacesAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoNamespaces] := QuerySiteInfoNamespacesParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespacesParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoNamespacesStrings);
  if OwnsStrings then
    FQuerySiteInfoNamespacesStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoNamespacesParseXmlResult(XML, FQuerySiteInfoNamespacesStrings);

    if Assigned(FOnQuerySiteInfoNamespacesDone) then
      FOnQuerySiteInfoNamespacesDone(Self, FQuerySiteInfoNamespacesStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoNamespacesStrings)
    else
      FQuerySiteInfoNamespacesStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespaceAliases(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoNamespaceAliasesStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoNamespaceAliases);
    MediaWikiQuerySiteInfoNamespaceAliasesAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoNamespaceAliasesParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoNamespaceAliases(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoNamespaceAliases);
  MediaWikiQuerySiteInfoNamespaceAliasesAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespaceAliasesAsync;
begin
  CheckRequest(mwrQuerySiteInfoNamespaceAliases);
  MediaWikiQuerySiteInfoNamespaceAliasesAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoNamespaceAliases] := QuerySiteInfoNamespaceAliasesParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoNamespaceAliasesParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoNamespaceAliasesStrings);
  if OwnsStrings then
    FQuerySiteInfoNamespaceAliasesStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoNamespaceAliasesParseXmlResult(XML, FQuerySiteInfoNamespaceAliasesStrings);

    if Assigned(FOnQuerySiteInfoNamespaceAliasesDone) then
      FOnQuerySiteInfoNamespaceAliasesDone(Self, FQuerySiteInfoNamespaceAliasesStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoNamespaceAliasesStrings)
    else
      FQuerySiteInfoNamespaceAliasesStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoSpecialPageAliases(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoSpecialPageAliasesStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoSpecialPageAliases);
    MediaWikiQuerySiteInfoSpecialPageAliasesAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoSpecialPageAliasesParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoSpecialPageAliases(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoSpecialPageAliases);
  MediaWikiQuerySiteInfoSpecialPageAliasesAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoSpecialPageAliasesAsync;
begin
  CheckRequest(mwrQuerySiteInfoSpecialPageAliases);
  MediaWikiQuerySiteInfoSpecialPageAliasesAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoSpecialPageAliases] := QuerySiteInfoSpecialPageAliasesParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoSpecialPageAliasesParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoSpecialPageAliasesStrings);
  if OwnsStrings then
    FQuerySiteInfoSpecialPageAliasesStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoSpecialPageAliasesParseXmlResult(XML, FQuerySiteInfoSpecialPageAliasesStrings);

    if Assigned(FOnQuerySiteInfoSpecialPageAliasesDone) then
      FOnQuerySiteInfoSpecialPageAliasesDone(Self, FQuerySiteInfoSpecialPageAliasesStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoSpecialPageAliasesStrings)
    else
      FQuerySiteInfoSpecialPageAliasesStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoMagicWords(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoMagicWordsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoMagicWords);
    MediaWikiQuerySiteInfoMagicWordsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoMagicWordsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoMagicWords(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoMagicWords);
  MediaWikiQuerySiteInfoMagicWordsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoMagicWordsAsync;
begin
  CheckRequest(mwrQuerySiteInfoMagicWords);
  MediaWikiQuerySiteInfoMagicWordsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoMagicWords] := QuerySiteInfoMagicWordsParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoMagicWordsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoMagicWordsStrings);
  if OwnsStrings then
    FQuerySiteInfoMagicWordsStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoMagicWordsParseXmlResult(XML, FQuerySiteInfoMagicWordsStrings);

    if Assigned(FOnQuerySiteInfoMagicWordsDone) then
      FOnQuerySiteInfoMagicWordsDone(Self, FQuerySiteInfoMagicWordsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoMagicWordsStrings)
    else
      FQuerySiteInfoMagicWordsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoStatistics(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoStatisticsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoStatistics);
    MediaWikiQuerySiteInfoStatisticsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoStatisticsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoStatistics(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoStatistics);
  MediaWikiQuerySiteInfoStatisticsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoStatisticsAsync;
begin
  CheckRequest(mwrQuerySiteInfoStatistics);
  MediaWikiQuerySiteInfoStatisticsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoStatistics] := QuerySiteInfoStatisticsParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoStatisticsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoStatisticsStrings);
  if OwnsStrings then
    FQuerySiteInfoStatisticsStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoStatisticsParseXmlResult(XML, FQuerySiteInfoStatisticsStrings);

    if Assigned(FOnQuerySiteInfoStatisticsDone) then
      FOnQuerySiteInfoStatisticsDone(Self, FQuerySiteInfoStatisticsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoStatisticsStrings)
    else
      FQuerySiteInfoStatisticsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoInterWikiMap(Local: Boolean; Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoInterWikiMapStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoInterWikiMap);
    MediaWikiQuerySiteInfoInterWikiMapAdd(FQueryStrings, Local, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoInterWikiMapParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoInterWikiMap(Local: Boolean;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoInterWikiMap);
  MediaWikiQuerySiteInfoInterWikiMapAdd(FQueryStrings, Local, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoInterWikiMapAsync(Local: Boolean);
begin
  CheckRequest(mwrQuerySiteInfoInterWikiMap);
  MediaWikiQuerySiteInfoInterWikiMapAdd(FQueryStrings, Local, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoInterWikiMap] := QuerySiteInfoInterWikiMapParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoInterWikiMapParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoInterWikiMapStrings);
  if OwnsStrings then
    FQuerySiteInfoInterWikiMapStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoInterWikiMapParseXmlResult(XML, FQuerySiteInfoInterWikiMapStrings);

    if Assigned(FOnQuerySiteInfoInterWikiMapDone) then
      FOnQuerySiteInfoInterWikiMapDone(Self, FQuerySiteInfoInterWikiMapStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoInterWikiMapStrings)
    else
      FQuerySiteInfoInterWikiMapStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoDBReplLag(ShowAllDB: Boolean; Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoDBReplLagStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoDBReplLag);
    MediaWikiQuerySiteInfoDBReplLagAdd(FQueryStrings, ShowAllDB, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoDBReplLagParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoDBReplLag(ShowAllDB: Boolean;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoDBReplLag);
  MediaWikiQuerySiteInfoDBReplLagAdd(FQueryStrings, ShowAllDB, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoDBReplLagAsync(ShowAllDB: Boolean);
begin
  CheckRequest(mwrQuerySiteInfoDBReplLag);
  MediaWikiQuerySiteInfoDBReplLagAdd(FQueryStrings, ShowAllDB, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoDBReplLag] := QuerySiteInfoDBReplLagParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoDBReplLagParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoDBReplLagStrings);
  if OwnsStrings then
    FQuerySiteInfoDBReplLagStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoDBReplLagParseXmlResult(XML, FQuerySiteInfoDBReplLagStrings);

    if Assigned(FOnQuerySiteInfoDBReplLagDone) then
      FOnQuerySiteInfoDBReplLagDone(Self, FQuerySiteInfoDBReplLagStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoDBReplLagStrings)
    else
      FQuerySiteInfoDBReplLagStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoUserGroups(IncludeUserCount: Boolean; Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQuerySiteInfoUserGroupsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoUserGroups);
    MediaWikiQuerySiteInfoUserGroupsAdd(FQueryStrings, IncludeUserCount, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoUserGroupsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoUserGroups(IncludeUserCount: Boolean;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoUserGroups);
  MediaWikiQuerySiteInfoUserGroupsAdd(FQueryStrings, IncludeUserCount, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoUserGroupsAsync(IncludeUserCount: Boolean);
begin
  CheckRequest(mwrQuerySiteInfoUserGroups);
  MediaWikiQuerySiteInfoUserGroupsAdd(FQueryStrings, IncludeUserCount, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoUserGroups] := QuerySiteInfoUserGroupsParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoUserGroupsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQuerySiteInfoUserGroupsStrings);
  if OwnsStrings then
    FQuerySiteInfoUserGroupsStrings := TStringList.Create;
  try
    MediaWikiQuerySiteInfoUserGroupsParseXmlResult(XML, FQuerySiteInfoUserGroupsStrings);

    if Assigned(FOnQuerySiteInfoUserGroupsDone) then
      FOnQuerySiteInfoUserGroupsDone(Self, FQuerySiteInfoUserGroupsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQuerySiteInfoUserGroupsStrings)
    else
      FQuerySiteInfoUserGroupsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QuerySiteInfoExtensions(out Infos: TMediaWikiExtensions);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQuerySiteInfoExtensions, 0);
  try
    QueryInit;
    CheckRequest(mwrQuerySiteInfoExtensions);
    MediaWikiQuerySiteInfoExtensionsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QuerySiteInfoExtensionsParseXmlResult(Self, XML);
  finally
    Infos := FQuerySiteInfoExtensions;
    FQuerySiteInfoExtensions := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QuerySiteInfoExtensions(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQuerySiteInfoExtensions);
  MediaWikiQuerySiteInfoExtensionsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QuerySiteInfoExtensionsAsync;
begin
  CheckRequest(mwrQuerySiteInfoExtensions);
  MediaWikiQuerySiteInfoExtensionsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQuerySiteInfoExtensions] := QuerySiteInfoExtensionsParseXmlResult;
end;

procedure TMediaWikiApi.QuerySiteInfoExtensionsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQuerySiteInfoExtensionsParseXmlResult(XML, FQuerySiteInfoExtensions);

  if Assigned(FOnQuerySiteInfoExtensionsDone) then
    FOnQuerySiteInfoExtensionsDone(Self, FQuerySiteInfoExtensions);
end;

procedure TMediaWikiApi.QueryTokensParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryTokensParseXmlResult(XML, FQueryTokenValues);

  if Assigned(FOnQueryTokensDone) then
    FOnQueryTokensDone(Self, FQueryTokenValues);
end;

procedure TMediaWikiApi.QueryTokens(Tokens: TMediaWikiTokens; out TokenValues: TMediaWikiTokenValues);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrQueryTokens);
    MediaWikiQueryTokensAdd(FQueryStrings, Tokens, mwoXML);
    QueryExecuteXML(XML);
    QueryTokensParseXmlResult(Self, XML);
    TokenValues := FQueryTokenValues;
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryTokens(Tokens: TMediaWikiTokens; OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryTokens);
  MediaWikiQueryTokensAdd(FQueryStrings, Tokens, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryTokensAsync(Tokens: TMediaWikiTokens);
begin
  CheckRequest(mwrQueryTokens);
  MediaWikiQueryTokensAdd(FQueryStrings, Tokens, mwoXML);
  FRequestCallbacks[mwrQueryTokens] := QueryTokensParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoBlockInfo(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryUserInfoBlockInfoStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoBlockInfo);
    MediaWikiQueryUserInfoBlockInfoAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoBlockInfoParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoBlockInfo(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoBlockInfo);
  MediaWikiQueryUserInfoBlockInfoAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoBlockInfoAsync;
begin
  CheckRequest(mwrQueryUserInfoBlockInfo);
  MediaWikiQueryUserInfoBlockInfoAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoBlockInfo] := QueryUserInfoBlockInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoBlockInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryUserInfoBlockInfoStrings);
  if OwnsStrings then
    FQueryUserInfoBlockInfoStrings := TStringList.Create;
  try
    MediaWikiQueryUserInfoBlockInfoParseXmlResult(XML, FQueryUserInfoBlockInfoStrings);

    if Assigned(FOnQueryUserInfoBlockInfoDone) then
      FOnQueryUserInfoBlockInfoDone(Self, FQueryUserInfoBlockInfoStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryUserInfoBlockInfoStrings)
    else
      FQueryUserInfoBlockInfoStrings := nil;
  end;
end;

function TMediaWikiApi.QueryUserInfoHasMsg: Boolean;
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoHasMsg);
    MediaWikiQueryUserInfoHasMsgAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoHasMsgParseXmlResult(Self, XML);
  finally
    Result := FQueryUserInfoHasMsg;
    FQueryUserInfoHasMsg := False;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoHasMsg(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoHasMsg);
  MediaWikiQueryUserInfoHasMsgAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoHasMsgAsync;
begin
  CheckRequest(mwrQueryUserInfoHasMsg);
  MediaWikiQueryUserInfoHasMsgAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoHasMsg] := QueryUserInfoHasMsgParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoHasMsgParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryUserInfoHasMsgParseXmlResult(XML, FQueryUserInfoHasMsg);

  if Assigned(FOnQueryUserInfoHasMsgDone) then
    FOnQueryUserInfoHasMsgDone(Self, FQueryUserInfoHasMsg);
end;

procedure TMediaWikiApi.QueryUserInfoGroups(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryUserInfoGroupsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoGroups);
    MediaWikiQueryUserInfoGroupsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoGroupsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoGroups(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoGroups);
  MediaWikiQueryUserInfoGroupsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoGroupsAsync;
begin
  CheckRequest(mwrQueryUserInfoGroups);
  MediaWikiQueryUserInfoGroupsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoGroups] := QueryUserInfoGroupsParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoGroupsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryUserInfoGroupsStrings);
  if OwnsStrings then
    FQueryUserInfoGroupsStrings := TStringList.Create;
  try
    MediaWikiQueryUserInfoGroupsParseXmlResult(XML, FQueryUserInfoGroupsStrings);

    if Assigned(FOnQueryUserInfoGroupsDone) then
      FOnQueryUserInfoGroupsDone(Self, FQueryUserInfoGroupsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryUserInfoGroupsStrings)
    else
      FQueryUserInfoGroupsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QueryUserInfoRights(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryUserInfoRightsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoRights);
    MediaWikiQueryUserInfoRightsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoRightsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoRights(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoRights);
  MediaWikiQueryUserInfoRightsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoRightsAsync;
begin
  CheckRequest(mwrQueryUserInfoRights);
  MediaWikiQueryUserInfoRightsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoRights] := QueryUserInfoRightsParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoRightsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryUserInfoRightsStrings);
  if OwnsStrings then
    FQueryUserInfoRightsStrings := TStringList.Create;
  try
    MediaWikiQueryUserInfoRightsParseXmlResult(XML, FQueryUserInfoRightsStrings);

    if Assigned(FOnQueryUserInfoRightsDone) then
      FOnQueryUserInfoRightsDone(Self, FQueryUserInfoRightsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryUserInfoRightsStrings)
    else
      FQueryUserInfoRightsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QueryUserInfoChangeableGroups(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryUserInfoChangeableGroupsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoChangeableGroups);
    MediaWikiQueryUserInfoChangeableGroupsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoChangeableGroupsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoChangeableGroups(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoChangeableGroups);
  MediaWikiQueryUserInfoChangeableGroupsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoChangeableGroupsAsync;
begin
  CheckRequest(mwrQueryUserInfoChangeableGroups);
  MediaWikiQueryUserInfoChangeableGroupsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoChangeableGroups] := QueryUserInfoChangeableGroupsParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoChangeableGroupsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryUserInfoChangeableGroupsStrings);
  if OwnsStrings then
    FQueryUserInfoChangeableGroupsStrings := TStringList.Create;
  try
    MediaWikiQueryUserInfoChangeableGroupsParseXmlResult(XML, FQueryUserInfoChangeableGroupsStrings);

    if Assigned(FOnQueryUserInfoChangeableGroupsDone) then
      FOnQueryUserInfoChangeableGroupsDone(Self, FQueryUserInfoChangeableGroupsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryUserInfoChangeableGroupsStrings)
    else
      FQueryUserInfoChangeableGroupsStrings := nil;
  end;
end;

procedure TMediaWikiApi.QueryUserInfoOptions(Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryUserInfoOptionsStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoOptions);
    MediaWikiQueryUserInfoOptionsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoOptionsParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoOptions(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoOptions);
  MediaWikiQueryUserInfoOptionsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoOptionsAsync;
begin
  CheckRequest(mwrQueryUserInfoOptions);
  MediaWikiQueryUserInfoOptionsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoOptions] := QueryUserInfoOptionsParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoOptionsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryUserInfoOptionsStrings);
  if OwnsStrings then
    FQueryUserInfoOptionsStrings := TStringList.Create;
  try
    MediaWikiQueryUserInfoOptionsParseXmlResult(XML, FQueryUserInfoOptionsStrings);

    if Assigned(FOnQueryUserInfoOptionsDone) then
      FOnQueryUserInfoOptionsDone(Self, FQueryUserInfoOptionsStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryUserInfoOptionsStrings)
    else
      FQueryUserInfoOptionsStrings := nil;
  end;
end;

function TMediaWikiApi.QueryUserInfoEditCount: Integer;
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoEditCount);
    MediaWikiQueryUserInfoEditCountAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoEditCountParseXmlResult(Self, XML);
  finally
    Result := FQueryUserInfoEditCount;
    FQueryUserInfoEditCount := 0;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoEditCount(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoEditCount);
  MediaWikiQueryUserInfoEditCountAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoEditCountAsync;
begin
  CheckRequest(mwrQueryUserInfoEditCount);
  MediaWikiQueryUserInfoEditCountAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoEditCount] := QueryUserInfoEditCountParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoEditCountParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryUserInfoEditCountParseXmlResult(XML, FQueryUserInfoEditCount);

  if Assigned(FOnQueryUserInfoEditCountDone) then
    FOnQueryUserInfoEditCountDone(Self, FQueryUserInfoEditCount);
end;

procedure TMediaWikiApi.QueryUserInfoRateLimits(out Infos: TMediaWikiRateLimits);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryUserInfoRateLimits, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryUserInfoRateLimits);
    MediaWikiQueryUserInfoRateLimitsAdd(FQueryStrings, mwoXML);
    QueryExecuteXML(XML);
    QueryUserInfoRateLimitsParseXmlResult(Self, XML);
  finally
    Infos := FQueryUserInfoRateLimits;
    FQueryUserInfoRateLimits := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryUserInfoRateLimits(
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryUserInfoRateLimits);
  MediaWikiQueryUserInfoRateLimitsAdd(FQueryStrings, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryUserInfoRateLimitsAsync;
begin
  CheckRequest(mwrQueryUserInfoRateLimits);
  MediaWikiQueryUserInfoRateLimitsAdd(FQueryStrings, mwoXML);
  FRequestCallbacks[mwrQueryUserInfoRateLimits] := QueryUserInfoRateLimitsParseXmlResult;
end;

procedure TMediaWikiApi.QueryUserInfoRateLimitsParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryUserInfoRateLimitsParseXmlResult(XML, FQueryUserInfoRateLimits);

  if Assigned(FOnQueryUserInfoRateLimitsDone) then
    FOnQueryUserInfoRateLimitsDone(Self, FQueryUserInfoRateLimits);
end;

procedure TMediaWikiApi.QueryMessages(const NameFilter, ContentFilter, Lang: string;
  Infos: TStrings);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryMessagesStrings := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryMessages);
    MediaWikiQueryMessagesAdd(FQueryStrings, NameFilter, ContentFilter, Lang, mwoXML);
    QueryExecuteXML(XML);
    QueryMessagesParseXmlResult(Self, XML);
  finally
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryMessages(const NameFilter, ContentFilter, Lang: string;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryMessages);
  MediaWikiQueryMessagesAdd(FQueryStrings, NameFilter, ContentFilter, Lang, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryMessagesAsync(const NameFilter, ContentFilter, Lang: string);
begin
  CheckRequest(mwrQueryMessages);
  MediaWikiQueryMessagesAdd(FQueryStrings, NameFilter, ContentFilter, Lang, mwoXML);
  FRequestCallbacks[mwrQueryMessages] := QueryMessagesParseXmlResult;
end;

procedure TMediaWikiApi.QueryMessagesParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryMessagesStrings);
  if OwnsStrings then
    FQueryMessagesStrings := TStringList.Create;
  try
    MediaWikiQueryMessagesParseXmlResult(XML, FQueryMessagesStrings);

    if Assigned(FOnQueryMessagesDone) then
      FOnQueryMessagesDone(Self, FQueryMessagesStrings);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryMessagesStrings)
    else
      FQueryMessagesStrings := nil;
  end;
end;

procedure TMediaWikiApi.QueryPageInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageInfoFlags; out Infos: TMediaWikiPageInfos);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageInfo);
    MediaWikiQueryPageInfoAdd(FQueryStrings, Titles, PageID, Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryPageInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageInfos;
    FQueryPageInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageInfoFlags; OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageInfo);
  MediaWikiQueryPageInfoAdd(FQueryStrings, Titles, PageID, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageInfoAsync(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageInfoFlags);
begin
  CheckRequest(mwrQueryPageInfo);
  MediaWikiQueryPageInfoAdd(FQueryStrings, Titles, PageID, Flags, mwoXML);
  FRequestCallbacks[mwrQueryPageInfo] := QueryPageInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageInfoParseXmlResult(XML, FQueryPageInfos);

  if Assigned(FOnQueryPageInfoDone) then
    FOnQueryPageInfoDone(Self, FQueryPageInfos);
end;

procedure TMediaWikiApi.QueryPageRevisionInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageRevisionInfoFlags; out Infos: TMediaWikiPageRevisionInfos;
  var ContinueInfo: TMediaWikiContinueInfo;
  MaxRevisions, Section: Integer; StartRevisionID, EndRevisionID: TMediaWikiID;
  const StartDateTime, EndDateTime: TDateTime; const IncludeUser, ExcludeUser: string);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageRevisionInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageRevisionInfo);
    MediaWikiQueryPageRevisionInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxRevisions, Section, StartRevisionID,
      EndRevisionID, StartDateTime, EndDateTime, IncludeUser, ExcludeUser, mwoXML);
    QueryExecuteXML(XML);
    QueryPageRevisionInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageRevisionInfos;
    ContinueInfo := FQueryPageRevisionContinueInfo;
    FQueryPageRevisionInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageRevisionInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageRevisionInfoFlags; OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo;
  MaxRevisions, Section: Integer; StartRevisionID, EndRevisionID: TMediaWikiID;
  const StartDateTime, EndDateTime: TDateTime; const IncludeUser, ExcludeUser: string): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageRevisionInfo);
  MediaWikiQueryPageRevisionInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxRevisions, Section, StartRevisionID,
    EndRevisionID, StartDateTime, EndDateTime, IncludeUser, ExcludeUser, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageRevisionInfoAsync(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageRevisionInfoFlags; const ContinueInfo: TMediaWikiContinueInfo;
  MaxRevisions, Section: Integer;
  StartRevisionID, EndRevisionID: TMediaWikiID; const StartDateTime, EndDateTime: TDateTime;
  const IncludeUser, ExcludeUser: string);
begin
  CheckRequest(mwrQueryPageRevisionInfo);
  MediaWikiQueryPageRevisionInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxRevisions, Section, StartRevisionID,
    EndRevisionID, StartDateTime, EndDateTime, IncludeUser, ExcludeUser, mwoXML);
  FRequestCallbacks[mwrQueryPageRevisionInfo] := QueryPageRevisionInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageRevisionInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageRevisionInfoParseXmlResult(XML, FQueryPageRevisionInfos, FQueryPageRevisionContinueInfo);

  if Assigned(FOnQueryPageRevisionInfoDone) then
    FOnQueryPageRevisionInfoDone(Self, FQueryPageRevisionInfos, FQueryPageRevisionContinueInfo);
end;

procedure TMediaWikiApi.QueryPageCategoryInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageCategoryInfoFlags; out Infos: TMediaWikiPageCategoryInfos;
  var ContinueInfo: TMediaWikiContinueInfo;
  MaxCategories: Integer; const CategoryTitles: string);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageCategoryInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageCategoryInfo);
    MediaWikiQueryPageCategoryInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxCategories, CategoryTitles, mwoXML);
    QueryExecuteXML(XML);
    QueryPageCategoryInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageCategoryInfos;
    ContinueInfo := FQueryPageCategoryContinueInfo;
    FQueryPageCategoryInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageCategoryInfo(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageCategoryInfoFlags; OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo;
  MaxCategories: Integer; const CategoryTitles: string): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageCategoryInfo);
  MediaWikiQueryPageCategoryInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxCategories, CategoryTitles, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageCategoryInfoAsync(const Titles: string; PageID: Boolean;
  Flags: TMediaWikiPageCategoryInfoFlags; const ContinueInfo: TMediaWikiContinueInfo;
  MaxCategories: Integer; const CategoryTitles: string);
begin
  CheckRequest(mwrQueryPageCategoryInfo);
  MediaWikiQueryPageCategoryInfoAdd(FQueryStrings, Titles, PageID, Flags, ContinueInfo, MaxCategories, CategoryTitles, mwoXML);
  FRequestCallbacks[mwrQueryPageCategoryInfo] := QueryPageCategoryInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageCategoryInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageCategoryInfoParseXmlResult(XML, FQueryPageCategoryInfos, FQueryPageCategoryContinueInfo);

  if Assigned(FOnQueryPageCategoryInfoDone) then
    FOnQueryPageCategoryInfoDone(Self, FQueryPageCategoryInfos, FQueryPageCategoryContinueInfo);
end;

procedure TMediaWikiApi.QueryPageLinkInfo(const Titles: string; PageID: Boolean;
  out Infos: TMediaWikiPageLinkInfos; var ContinueInfo: TMediaWikiContinueInfo;
  MaxLinks, Namespace: Integer);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageLinkInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageLinkInfo);
    MediaWikiQueryPageLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, Namespace, mwoXML);
    QueryExecuteXML(XML);
    QueryPageLinkInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageLinkInfos;
    ContinueInfo := FQueryPageLinkContinueInfo;
    FQueryPageLinkInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageLinkInfo(const Titles: string; PageID: Boolean;
  OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  MaxLinks, Namespace: Integer): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageLinkInfo);
  MediaWikiQueryPageLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, NameSpace, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageLinkInfoAsync(const Titles: string; PageID: Boolean;
  const ContinueInfo: TMediaWikiContinueInfo; MaxLinks, Namespace: Integer);
begin
  CheckRequest(mwrQueryPageLinkInfo);
  MediaWikiQueryPageLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, Namespace, mwoXML);
  FRequestCallbacks[mwrQueryPageLinkInfo] := QueryPageLinkInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageLinkInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageLinkInfoParseXmlResult(XML, FQueryPageLinkInfos, FQueryPageLinkContinueInfo);

  if Assigned(FOnQueryPageLinkInfoDone) then
    FOnQueryPageLinkInfoDone(Self, FQueryPageLinkInfos, FQueryPageLinkContinueInfo);
end;

procedure TMediaWikiApi.QueryPageTemplateInfo(const Titles: string; PageID: Boolean;
  out Infos: TMediaWikiPageTemplateInfos; var ContinueInfo: TMediaWikiContinueInfo;
  MaxTemplates, Namespace: Integer);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageTemplateInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageTemplateInfo);
    MediaWikiQueryPageTemplateInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxTemplates, Namespace, mwoXML);
    QueryExecuteXML(XML);
    QueryPageTemplateInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageTemplateInfos;
    ContinueInfo := FQueryPageTemplateContinueInfo;
    FQueryPageTemplateInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageTemplateInfo(const Titles: string; PageID: Boolean;
  OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  MaxTemplates, Namespace: Integer): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageTemplateInfo);
  MediaWikiQueryPageTemplateInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxTemplates, Namespace, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageTemplateInfoAsync(const Titles: string; PageID: Boolean;
  const ContinueInfo: TMediaWikiContinueInfo; MaxTemplates, Namespace: Integer);
begin
  CheckRequest(mwrQueryPageTemplateInfo);
  MediaWikiQueryPageTemplateInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxTemplates, Namespace, mwoXML);
  FRequestCallbacks[mwrQueryPageTemplateInfo] := QueryPageTemplateInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageTemplateInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageTemplateInfoParseXmlResult(XML, FQueryPageTemplateInfos, FQueryPageTemplateContinueInfo);

  if Assigned(FOnQueryPageTemplateInfoDone) then
    FOnQueryPageTemplateInfoDone(Self, FQueryPageTemplateInfos, FQueryPageTemplateContinueInfo);
end;

procedure TMediaWikiApi.QueryPageExtLinkInfo(const Titles: string; PageID: Boolean;
  out Infos: TMediaWikiPageExtLinkInfos; var ContinueInfo: TMediaWikiContinueInfo;
  MaxLinks: Integer);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryPageExtLinkInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryPageExtLinkInfo);
    MediaWikiQueryPageExtLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, mwoXML);
    QueryExecuteXML(XML);
    QueryPageExtLinkInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryPageExtLinkInfos;
    ContinueInfo := FQueryPageExtLinkContinueInfo;
    FQueryPageExtLinkInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryPageExtLinkInfo(const Titles: string; PageID: Boolean;
  OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  MaxLinks: Integer): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryPageExtLinkInfo);
  MediaWikiQueryPageExtLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryPageExtLinkInfoAsync(const Titles: string; PageID: Boolean;
  const ContinueInfo: TMediaWikiContinueInfo; MaxLinks: Integer);
begin
  CheckRequest(mwrQueryPageExtLinkInfo);
  MediaWikiQueryPageExtLinkInfoAdd(FQueryStrings, Titles, PageID, ContinueInfo, MaxLinks, mwoXML);
  FRequestCallbacks[mwrQueryPageExtLinkInfo] := QueryPageExtLinkInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryPageExtLinkInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryPageExtLinkInfoParseXmlResult(XML, FQueryPageExtLinkInfos, FQueryPageExtLinkContinueInfo);

  if Assigned(FOnQueryPageExtLinkInfoDone) then
    FOnQueryPageExtLinkInfoDone(Self, FQueryPageExtLinkInfos, FQueryPageExtLinkContinueInfo);
end;

procedure TMediaWikiApi.QueryAllPageInfo(out Infos: TMediaWikiAllPageInfos; var ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxPage, Namespace: Integer; RedirFilter: TMediaWikiAllPageFilterRedir;
  LangFilter: TMediaWikiAllPageFilterLang; MinSize, MaxSize: Integer;
  ProtectionFilter: TMediaWikiAllPageFilterProtection; LevelFilter: TMediaWikiAllPageFilterLevel;
  Direction: TMediaWikiAllPageDirection);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryAllPageInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryAllPageInfo);
    MediaWikiQueryAllPageAdd(FQueryStrings, ContinueInfo, Prefix, MaxPage, Namespace, RedirFilter,
      LangFilter, MinSize, MaxSize, ProtectionFilter, LevelFilter, Direction, mwoXML);
    QueryExecuteXML(XML);
    QueryAllPageInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryAllPageInfos;
    ContinueInfo := FQueryAllPageContinueInfo;
    FQueryAllPageInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryAllPageInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxPage, Namespace: Integer; RedirFilter: TMediaWikiAllPageFilterRedir;
  LangFilter: TMediaWikiAllPageFilterLang; MinSize, MaxSize: Integer;
  ProtectionFilter: TMediaWikiAllPageFilterProtection; LevelFilter: TMediaWikiAllPageFilterLevel;
  Direction: TMediaWikiAllPageDirection): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryAllPageInfo);
  MediaWikiQueryAllPageAdd(FQueryStrings, ContinueInfo, Prefix, MaxPage, Namespace, RedirFilter,
    LangFilter, MinSize, MaxSize, ProtectionFilter, LevelFilter, Direction, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryAllPageInfoAsync(const ContinueInfo: TMediaWikiContinueInfo; const Prefix: string;
  MaxPage, Namespace: Integer; RedirFilter: TMediaWikiAllPageFilterRedir;
  LangFilter: TMediaWikiAllPageFilterLang; MinSize, MaxSize: Integer;
  ProtectionFilter: TMediaWikiAllPageFilterProtection; LevelFilter: TMediaWikiAllPageFilterLevel;
  Direction: TMediaWikiAllPageDirection);
begin
  CheckRequest(mwrQueryAllPageInfo);
  MediaWikiQueryAllPageAdd(FQueryStrings, ContinueInfo, Prefix, MaxPage, Namespace, RedirFilter,
    LangFilter, MinSize, MaxSize, ProtectionFilter, LevelFilter, Direction, mwoXML);
  FRequestCallbacks[mwrQueryAllPageInfo] := QueryAllPageInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryAllPageInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryAllPageParseXmlResult(XML, FQueryAllPageInfos, FQueryAllPageContinueInfo);

  if Assigned(FOnQueryAllPageInfoDone) then
    FOnQueryAllPageInfoDone(Self, FQueryAllPageInfos, FQueryAllPageContinueInfo);
end;

procedure TMediaWikiApi.QueryAllLinkInfo(out Infos: TMediaWikiAllLinkInfos; var ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxLink: Integer; Namespace: Integer;
  Flags: TMediaWikiAllLinkInfoFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryAllLinkInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryAllLinkInfo);
    MediaWikiQueryAllLinkAdd(FQueryStrings, ContinueInfo, Prefix, MaxLink, Namespace,
      Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryAllLinkInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryAllLinkInfos;
    ContinueInfo := FQueryAllLinkContinueInfo;
    FQueryAllLinkInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryAllLinkInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxLink: Integer; Namespace: Integer; Flags: TMediaWikiAllLinkInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryAllLinkInfo);
  MediaWikiQueryAllLinkAdd(FQueryStrings, ContinueInfo, Prefix, MaxLink, Namespace,
    Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryAllLinkInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxLink: Integer; Namespace: Integer; Flags: TMediaWikiAllLinkInfoFlags);
begin
  CheckRequest(mwrQueryAllLinkInfo);
  MediaWikiQueryAllLinkAdd(FQueryStrings, ContinueInfo, Prefix, MaxLink, Namespace,
    Flags, mwoXML);
  FRequestCallbacks[mwrQueryAllLinkInfo] := QueryAllLinkInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryAllLinkInfoParseXmlResult(Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryAllLinkParseXmlResult(XML, FQueryAllLinkInfos, FQueryAllLinkContinueInfo);

  if Assigned(FOnQueryAllLinkInfoDone) then
    FOnQueryAllLinkInfoDone(Self, FQueryAllLinkInfos, FQueryAllLinkContinueInfo);
end;

procedure TMediaWikiApi.QueryAllCategoryInfo(Infos: TStrings; var ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxCategory: Integer;
  Flags: TMediaWikiAllCategoryInfoFlags);
var
  XML: TJclSimpleXML;
begin
  Infos.Clear;
  XML := TJclSimpleXML.Create;
  FQueryAllCategoryInfos := Infos;
  try
    QueryInit;
    CheckRequest(mwrQueryAllCategoryInfo);
    MediaWikiQueryAllCategoryAdd(FQueryStrings, ContinueInfo, Prefix, MaxCategory,
      Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryAllCategoryInfoParseXmlResult(Self, XML);
  finally
    ContinueInfo := FQueryAllCategoryContinueInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryAllCategoryInfo(OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo; const Prefix: string;
  MaxCategory: Integer; Flags: TMediaWikiAllCategoryInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryAllCategoryInfo);
  MediaWikiQueryAllCategoryAdd(FQueryStrings, ContinueInfo, Prefix, MaxCategory,
    Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryAllCategoryInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
  const Prefix: string; MaxCategory: Integer;
  Flags: TMediaWikiAllCategoryInfoFlags);
begin
  CheckRequest(mwrQueryAllCategoryInfo);
  MediaWikiQueryAllCategoryAdd(FQueryStrings, ContinueInfo, Prefix, MaxCategory,
    Flags, mwoXML);
  FRequestCallbacks[mwrQueryAllCategoryInfo] := QueryAllCategoryInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryAllCategoryInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
var
  OwnsStrings: Boolean;
begin
  OwnsStrings := not Assigned(FQueryAllCategoryInfos);
  if OwnsStrings then
    FQueryAllCategoryInfos := TStringList.Create;
  try
    MediaWikiQueryAllCategoryParseXmlResult(XML, FQueryAllCategoryInfos, FQueryAllCategoryContinueInfo);

    if Assigned(FOnQueryAllCategoryInfoDone) then
      FOnQueryAllCategoryInfoDone(Self, FQueryAllCategoryInfos, FQueryAllCategoryContinueInfo);
  finally
    if OwnsStrings then
      FreeAndNil(FQueryAllCategoryInfos)
    else
      FQueryAllCategoryInfos := nil;
  end;
end;

procedure TMediaWikiApi.QueryAllUserInfo(out Infos: TMediaWikiAllUserInfos; var ContinueInfo: TMediaWikiContinueInfo;
  const Prefix, Group: string; MaxUser: Integer; Flags: TMediaWikiAllUserInfoFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryAllUserInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryAllUserInfo);
    MediaWikiQueryAllUserAdd(FQueryStrings, ContinueInfo, Prefix, Group, MaxUser, Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryAllUserInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryAllUserInfos;
    ContinueInfo := FQueryAllUserContinueInfo;
    FQueryAllUserInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryAllUserInfo(OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo; const Prefix, Group: string;
  MaxUser: Integer; Flags: TMediaWikiAllUserInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryAllUserInfo);
  MediaWikiQueryAllUserAdd(FQueryStrings, ContinueInfo, Prefix, Group, MaxUser, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryAllUserInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
  const Prefix, Group: string; MaxUser: Integer; Flags: TMediaWikiAllUserInfoFlags);
begin
  CheckRequest(mwrQueryAllUserInfo);
  MediaWikiQueryAllUserAdd(FQueryStrings, ContinueInfo, Prefix, Group, MaxUser, Flags, mwoXML);
  FRequestCallbacks[mwrQueryAllUserInfo] := QueryAllUserInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryAllUserInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryAllUserParseXmlResult(XML, FQueryAllUserInfos, FQueryAllUserContinueInfo);

  if Assigned(FOnQueryAllUserInfoDone) then
    FOnQueryAllUserInfoDone(Self, FQueryAllUserInfos, FQueryAllUserContinueInfo);
end;

procedure TMediaWikiApi.QueryBackLinkInfo(const BackLinkTitle: string; out Infos: TMediaWikiBackLinkInfos;
  var ContinueInfo: TMediaWikiContinueInfo; Namespace, MaxLink: Integer; Flags: TMediaWikiBackLinkInfoFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryBackLinkInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryBackLinkInfo);
    MediaWikiQueryBackLinkAdd(FQueryStrings, BackLinkTitle, ContinueInfo, Namespace, MaxLink, Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryBackLinkInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryBackLinkInfos;
    ContinueInfo := FQueryBackLinkContinueInfo;
    FQueryBackLinkInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryBackLinkInfo(const BackLinkTitle: string; OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo; Namespace, MaxLink: Integer; Flags: TMediaWikiBackLinkInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryBackLinkInfo);
  MediaWikiQueryBackLinkAdd(FQueryStrings, BackLinkTitle, ContinueInfo, Namespace, MaxLink, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryBackLinkInfoAsync(const BackLinkTitle: string;
  const ContinueInfo: TMediaWikiContinueInfo; Namespace, MaxLink: Integer; Flags: TMediaWikiBackLinkInfoFlags);
begin
  CheckRequest(mwrQueryBackLinkInfo);
  MediaWikiQueryBackLinkAdd(FQueryStrings, BackLinkTitle, ContinueInfo, Namespace, MaxLink, Flags, mwoXML);
  FRequestCallbacks[mwrQueryBackLinkInfo] := QueryBackLinkInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryBackLinkInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryBackLinkParseXmlResult(XML, FQueryBackLinkInfos, FQueryBackLinkContinueInfo);

  if Assigned(FOnQueryBackLinkInfoDone) then
    FOnQueryBackLinkInfoDone(Self, FQueryBackLinkInfos, FQueryBackLinkContinueInfo);
end;

procedure TMediaWikiApi.QueryBlockInfo(out Infos: TMediaWikiBlockInfos; var ContinueInfo: TMediaWikiContinueInfo;
  const StartDateTime, StopDateTime: TDateTime;
  const BlockIDs, Users, IP: string; MaxBlock: Integer; Flags: TMediaWikiBlockInfoFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryBlockInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryBlockInfo);
    MediaWikiQueryBlockAdd(FQueryStrings, ContinueInfo, StartDateTime, StopDateTime, BlockIDs, Users, IP, MaxBlock, Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryBlockInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryBlockInfos;
    ContinueInfo := FQueryBlockContinueInfo;
    FQueryBlockInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryBlockInfo(OutputFormat: TMediaWikiOutputFormat; const ContinueInfo: TMediaWikiContinueInfo;
  const StartDateTime, StopDateTime: TDateTime;
  const BlockIDs, Users, IP: string; MaxBlock: Integer; Flags: TMediaWikiBlockInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryBlockInfo);
  MediaWikiQueryBlockAdd(FQueryStrings, ContinueInfo, StartDateTime, StopDateTime, BlockIDs, Users, IP, MaxBlock, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryBlockInfoAsync(const ContinueInfo: TMediaWikiContinueInfo;
  const StartDateTime, StopDateTime: TDateTime;
  const BlockIDs, Users, IP: string; MaxBlock: Integer; Flags: TMediaWikiBlockInfoFlags);
begin
  CheckRequest(mwrQueryBlockInfo);
  MediaWikiQueryBlockAdd(FQueryStrings, ContinueInfo, StartDateTime, StopDateTime, BlockIDs, Users, IP, MaxBlock, Flags, mwoXML);
  FRequestCallbacks[mwrQueryBlockInfo] := QueryBlockInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryBlockInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryBlockParseXmlResult(XML, FQueryBlockInfos, FQueryBlockContinueInfo);

  if Assigned(FOnQueryBlockInfoDone) then
    FOnQueryBlockInfoDone(Self, FQueryBlockInfos, FQueryBlockContinueInfo);
end;

procedure TMediaWikiApi.QueryCategoryMemberInfo(const CategoryTitle: string; out Infos: TMediaWikiCategoryMemberInfos;
  var ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer; const StartDateTime, StopDateTime: TDateTime; const StartSortKey, StopSortKey: string;
  MaxCategoryMember: Integer; Flags: TMediaWikiCategoryMemberInfoFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  SetLength(FQueryCategoryMemberInfos, 0);
  try
    QueryInit;
    CheckRequest(mwrQueryCategoryMemberInfo);
    MediaWikiQueryCategoryMemberAdd(FQueryStrings, CategoryTitle, ContinueInfo, PageNamespace, StartDateTime, StopDateTime, StartSortKey, StopSortKey, MaxCategoryMember, Flags, mwoXML);
    QueryExecuteXML(XML);
    QueryCategoryMemberInfoParseXmlResult(Self, XML);
  finally
    Infos := FQueryCategoryMemberInfos;
    ContinueInfo := FQueryCategoryMemberContinueInfo;
    FQueryCategoryMemberInfos := nil;
    XML.Free;
  end;
end;

function TMediaWikiApi.QueryCategoryMemberInfo(const CategoryTitle: string; OutputFormat: TMediaWikiOutputFormat;
  const ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer; const StartDateTime, StopDateTime: TDateTime; const StartSortKey, StopSortKey: string;
  MaxCategoryMember: Integer; Flags: TMediaWikiCategoryMemberInfoFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrQueryCategoryMemberInfo);
  MediaWikiQueryCategoryMemberAdd(FQueryStrings, CategoryTitle, ContinueInfo, PageNamespace, StartDateTime, StopDateTime, StartSortKey, StopSortKey, MaxCategoryMember, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.QueryCategoryMemberInfoAsync(const CategoryTitle: string;
  const ContinueInfo: TMediaWikiContinueInfo; PageNamespace: Integer; const StartDateTime, StopDateTime: TDateTime; const StartSortKey, StopSortKey: string;
  MaxCategoryMember: Integer; Flags: TMediaWikiCategoryMemberInfoFlags);
begin
  CheckRequest(mwrQueryCategoryMemberInfo);
  MediaWikiQueryCategoryMemberAdd(FQueryStrings, CategoryTitle, ContinueInfo, PageNamespace, StartDateTime, StopDateTime, StartSortKey, StopSortKey, MaxCategoryMember, Flags, mwoXML);
  FRequestCallbacks[mwrQueryCategoryMemberInfo] := QueryCategoryMemberInfoParseXmlResult;
end;

procedure TMediaWikiApi.QueryCategoryMemberInfoParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiQueryCategoryMemberParseXmlResult(XML, FQueryCategoryMemberInfos, FQueryCategoryMemberContinueInfo);

  if Assigned(FOnQueryCategoryMemberInfoDone) then
    FOnQueryCategoryMemberInfoDone(Self, FQueryCategoryMemberInfos, FQueryCategoryMemberContinueInfo);
end;

procedure TMediaWikiApi.Edit(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary: string;
  out EditInfo: TMediaWikiEditInfo; const MD5, CaptchaID, CaptchaWord: string;
  const BaseDateTime, StartDateTime: TDateTime; UndoRevisionID: TMediaWikiID; Flags: TMediaWikiEditFlags);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrEdit);
    MediaWikiEditAdd(FQueryStrings, PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary, MD5, CaptchaID, CaptchaWord, BaseDateTime, StartDateTime, UndoRevisionID, Flags, mwoXML);
    QueryExecuteXML(XML);
    EditParseXmlResult(Self, XML);
  finally
    EditInfo := FEditInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.Edit(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary: string;
  OutputFormat: TMediaWikiOutputFormat; const MD5, CaptchaID, CaptchaWord: string;
  const BaseDateTime, StartDateTime: TDateTime; UndoRevisionID: TMediaWikiID; Flags: TMediaWikiEditFlags): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrEdit);
  MediaWikiEditAdd(FQueryStrings, PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary, MD5, CaptchaID, CaptchaWord, BaseDateTime, StartDateTime, UndoRevisionID, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.EditAsync(const PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary,
  MD5, CaptchaID, CaptchaWord: string; const BaseDateTime, StartDateTime: TDateTime;
  UndoRevisionID: TMediaWikiID; Flags: TMediaWikiEditFlags);
begin
  CheckRequest(mwrEdit);
  MediaWikiEditAdd(FQueryStrings, PageTitle, Section, Text, PrependText, AppendText, EditToken, Summary, MD5, CaptchaID, CaptchaWord, BaseDateTime, StartDateTime, UndoRevisionID, Flags, mwoXML);
  FRequestCallbacks[mwrEdit] := EditParseXmlResult;
end;

procedure TMediaWikiApi.EditParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiEditParseXmlResult(XML, FEditInfo);

  if Assigned(FOnEditDone) then
    FOnEditDone(Self, FEditInfo);
end;

procedure TMediaWikiApi.Move(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
  FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags; out MoveInfo: TMediaWikiMoveInfo);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrMove);
    MediaWikiMoveAdd(FQueryStrings, FromPageTitle, ToPageTitle, MoveToken, Reason, FromPageID, Flags, mwoXML);
    QueryExecuteXML(XML);
    MoveParseXmlResult(Self, XML);
  finally
    MoveInfo := FMoveInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.Move(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
  FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags; OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrMove);
  MediaWikiMoveAdd(FQueryStrings, FromPageTitle, ToPageTitle, MoveToken, Reason, FromPageID, Flags, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.MoveAsync(const FromPageTitle, ToPageTitle, MoveToken, Reason: string;
  FromPageID: TMediaWikiID; Flags: TMediaWikiMoveFlags);
begin
  CheckRequest(mwrMove);
  MediaWikiMoveAdd(FQueryStrings, FromPageTitle, ToPageTitle, MoveToken, Reason, FromPageID, Flags, mwoXML);
  FRequestCallbacks[mwrMove] := MoveParseXmlResult;
end;

procedure TMediaWikiApi.MoveParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiMoveParseXmlResult(XML, FMoveInfo);

  if Assigned(FOnMoveDone) then
    FOnMoveDone(Self, FMoveInfo);
end;

procedure TMediaWikiApi.Delete(const PageTitle, DeleteToken, Reason: string;
  FromPageID: TMediaWikiID; out DeleteInfo: TMediaWikiDeleteInfo; Suppress: Boolean);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrDelete);
    MediaWikiDeleteAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, Suppress, mwoXML);
    QueryExecuteXML(XML);
    DeleteParseXmlResult(Self, XML);
  finally
    DeleteInfo := FDeleteInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.Delete(const PageTitle, DeleteToken, Reason: string;
  FromPageID: TMediaWikiID; OutputFormat: TMediaWikiOutputFormat; Suppress: Boolean): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrDelete);
  MediaWikiDeleteAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, Suppress, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.DeleteAsync(const PageTitle, DeleteToken, Reason: string;
  FromPageID: TMediaWikiID; Suppress: Boolean);
begin
  CheckRequest(mwrDelete);
  MediaWikiDeleteAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, Suppress, mwoXML);
  FRequestCallbacks[mwrDelete] := DeleteParseXmlResult;
end;

procedure TMediaWikiApi.DeleteParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiDeleteParseXmlResult(XML, FDeleteInfo);

  if Assigned(FOnDeleteDone) then
    FOnDeleteDone(Self, FDeleteInfo);
end;

procedure TMediaWikiApi.DeleteRevision(const PageTitle, DeleteToken, Reason: string;
  FromPageID, RevisionID: TMediaWikiID; out DeleteRevisionInfo: TMediaWikiDeleteRevisionInfo);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrDeleteRevision);
    MediaWikiDeleteRevisionAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, RevisionID, mwoXML);
    QueryExecuteXML(XML);
    DeleteRevisionParseXmlResult(Self, XML);
  finally
    DeleteRevisionInfo := FDeleteRevisionInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.DeleteRevision(const PageTitle, DeleteToken, Reason: string;
  FromPageID, RevisionID: TMediaWikiID; OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrDeleteRevision);
  MediaWikiDeleteRevisionAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, RevisionID, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.DeleteRevisionAsync(const PageTitle, DeleteToken, Reason: string;
  FromPageID, RevisionID: TMediaWikiID);
begin
  CheckRequest(mwrDeleteRevision);
  MediaWikiDeleteRevisionAdd(FQueryStrings, PageTitle, DeleteToken, Reason, FromPageID, RevisionID, mwoXML);
  FRequestCallbacks[mwrDeleteRevision] := DeleteRevisionParseXmlResult;
end;

procedure TMediaWikiApi.DeleteRevisionParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiDeleteRevisionParseXmlResult(XML, FDeleteRevisionInfo);

  if Assigned(FOnDeleteRevisionDone) then
    FOnDeleteRevisionDone(Self, FDeleteRevisionInfo);
end;

procedure TMediaWikiApi.Upload(const FileName, Comment, Text, EditToken: string;
  Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string;
  out UploadInfo: TMediaWikiUploadInfo);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrUpload);
    MediaWikiUploadAdd(FQueryStrings, FileName, Comment, Text, EditToken, Flags, Content, URL, mwoXML);
    QueryExecuteXML(XML);
    UploadParseXmlResult(Self, XML);
  finally
    UploadInfo := FUploadInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.Upload(const FileName, Comment, Text, EditToken: string;
  Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string;
  OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrUpload);
  MediaWikiUploadAdd(FQueryStrings, FileName, Comment, Text, EditToken, Flags, Content, URL, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.UploadAsync(const FileName, Comment, Text, EditToken: string;
  Flags: TMediaWikiUploadFlags; Content: TStream; const URL: string);
begin
  CheckRequest(mwrUpload);
  MediaWikiUploadAdd(FQueryStrings, FileName, Comment, Text, EditToken, Flags, Content, URL, mwoXML);
  FRequestCallbacks[mwrUpload] := UploadParseXmlResult;
end;

procedure TMediaWikiApi.UploadParseXmlResult(
  Sender: TMediaWikiApi; XML: TJclSimpleXML);
begin
  MediaWikiUploadParseXmlResult(XML, FUploadInfo);

  if Assigned(FOnUploadDone) then
    FOnUploadDone(Self, FUploadInfo);
end;

procedure TMediaWikiApi.UserMerge(const OldUser, NewUser, Token: string;
  DeleteUser: Boolean; out UserMergeInfo: TMediaWikiUserMergeInfo);
var
  XML: TJclSimpleXML;
begin
  XML := TJclSimpleXML.Create;
  try
    QueryInit;
    CheckRequest(mwrUserMerge);
    MediaWikiUserMergeAdd(FQueryStrings, OldUser, NewUser, Token, DeleteUser, mwoXML);
    QueryExecuteXML(XML);
    UserMergeParseXmlResult(Self, XML);
  finally
    UserMergeInfo := FUserMergeInfo;
    XML.Free;
  end;
end;

function TMediaWikiApi.UserMerge(const OldUser, NewUser, Token: string;
  DeleteUser: Boolean; OutputFormat: TMediaWikiOutputFormat): AnsiString;
begin
  QueryInit;
  CheckRequest(mwrUserMerge);
  MediaWikiUserMergeAdd(FQueryStrings, OldUser, NewUser, Token, DeleteUser, OutputFormat);
  Result := QueryExecute;
end;

procedure TMediaWikiApi.UserMergeAsync(const OldUser, NewUser, Token: string; DeleteUser: Boolean);
begin
  CheckRequest(mwrUserMerge);
  MediaWikiUserMergeAdd(FQueryStrings, OldUser, NewUser, Token, DeleteUser, mwoXML);
  FRequestCallbacks[mwrUserMerge] := UserMergeParseXmlResult;
end;

procedure TMediaWikiApi.UserMergeParseXmlResult(Sender: TMediaWikiApi;
  XML: TJclSimpleXML);
begin
  MediaWikiUserMergeParseXmlResult(XML, FUserMergeInfo);

  if Assigned(FOnUserMergeDone) then
    FOnUserMergeDone(Self, FUserMergeInfo);
end;

procedure TMediaWikiApi.RequestDone(Sender: TObject; RqType: THttpRequest;
  ErrCode: Word);
var
  XML: TJclSimpleXML;

  function NeedXML: TJclSimpleXML;
  begin
    Result := XML;
    if not Assigned(Result) then
    begin
      XML := TJclSimpleXML.Create;

      FReceiveStream.Position := 0;
      XML.LoadFromStream(FReceiveStream, seUTF8);

      MediaWikiCheckXML(XML, ProcessXMLWarning, ProcessXMLError);

      Result := XML;
    end;
  end;

var
  Request: TMediaWikiRequest;
  Callback: TMediaWikiXMLCallback;
begin
  FPendingRequests := [];

  if ErrCode <> 0 then
    raise EMediaWikiException.Create('request error')
  else
  if FHttpsCli.StatusCode <> 200 then
    raise EMediaWikiException.Create('http request error');

  XML := nil;
  try
    for Request := Low(TMediaWikiRequest) to High(TMediaWikiRequest) do
    begin
      Callback := FRequestCallbacks[Request];
      FRequestCallbacks[Request] := nil;
      if Assigned(Callback) then
        Callback(Self, NeedXML);
    end;
  finally
    XML.Free;
  end;
end;

end.

