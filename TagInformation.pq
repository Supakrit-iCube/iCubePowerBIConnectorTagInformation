// This file contains your Data Connector logic
[Version = "1.0.0"]
section TagInformation;

[DataSource.Kind="TagInformation", Publish="TagInformation.Publish"]
shared TagInformation.Contents = Value.ReplaceType(Impl, Types);

Types = type function (
    ipAddress as (type text meta [
        Documentation.FieldCaption = "IP Address",
        Documentation.FieldDescription = "The IP address of the iCubeServer.",
        Documentation.SampleValues = ""
    ]),
    accessToken as (type text meta [
        Documentation.FieldCaption = "Factory Token",
        Documentation.FieldDescription = "factory token for access server, you can get token from iCube Server in overview pages.",
        Documentation.SampleValues = ""
    ]),
    tagtype as (type text meta [
        Documentation.FieldCaption = "Tags type",
        Documentation.FieldDescription = "Select tag type",
        Documentation.AllowedValues = { "Tag", "TagRelation"}
    ]),
    getTags as (type text meta [
        Documentation.FieldCaption = "Get all tag",
        Documentation.FieldDescription = "Enable this option to retrieve data for all tags without specifying individual tag values.",
        Documentation.AllowedValues = { "Get all Tags", "By Tags" }
    ]),
    optional tags as (type text meta [
        Documentation.FieldCaption = "Tag/TagRelation",
        Documentation.FieldDescription = "tagname for get data.",
        Documentation.SampleValues = ""
    ])
    )
    as table meta [
        Documentation.Name = "Tag Information"
    ];

    Impl = (ipAddress as text, accessToken as text, tagtype as text, getTags as text, optional tags as nullable text) as table =>
        let
            _tagtype = if tagtype = null or Text.Trim(tagtype) = "" then "Tag" else tagtype,
            _getTags  = if getTags = null then "Get all Tags" else getTags,
            _tags    = if tags = null then "" else Text.Trim(tags),

            // Base URL (fixed)
            BaseUrl = "https://" & ipAddress,

            // RelativePath (safer than concatenating full URL)
            PathPrefix =
                if _tagtype = "Tag"
                then "integration/web-api/tag/"
                else "integration/web-api/tag-relation/",

            RelativePath =
                if _getTags = "Get all Tags" and _tags = ""
                then PathPrefix
                else PathPrefix & _tags,

            Response =
                Web.Contents(
                    BaseUrl & "?PageSize=9999",
                    [
                        RelativePath = RelativePath,
                        Headers = [
                            Authorization = "Bearer " & accessToken,
                            Accept = "application/json"
                        ],
                        Timeout = #duration(0, 0, 30, 0)
                    ]
                ),

            JsonOut = Json.Document(Response),
            data = JsonOut[data],
            Items = try data[items] otherwise null,
            tableData = 
                if Items = null then
                    Table.FromRecords({ data })
                else
                    Table.FromRecords(Items),

        withTypes = tableData
        in
        withTypes;

    // ---------- 4) Data Source Kind ----------
    TagInformation = [
        TestConnection = (dataSourcePath) =>
            let
                json = Json.Document(dataSourcePath),
                ipAddress = json[ipAddress],
                accessToken = json[accessToken],
                tagtype = json[tagtype],
                getTags = json[getTags],
                tags = Record.FieldOrDefault(json, "tags", null)
            in
                { "TagInformation.Contents", ipAddress, accessToken, tagtype, getTags, tags },

        Authentication = [
            Anonymous = []
        ],

        Label = "iCube Data Connector"
    ];

// Data Source UI publishing description
TagInformation.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://docs.icube.co.th/",
    SourceImage = TagInformation.Icons,
    SourceTypeImage = TagInformation.Icons
];

TagInformation.Icons = [
    Icon16 = { Extension.Contents("TagInformation16.png"), Extension.Contents("TagInformation20.png"), Extension.Contents("TagInformation24.png"), Extension.Contents("TagInformation32.png") },
    Icon32 = { Extension.Contents("TagInformation32.png"), Extension.Contents("TagInformation40.png"), Extension.Contents("TagInformation48.png"), Extension.Contents("TagInformation64.png") }
];