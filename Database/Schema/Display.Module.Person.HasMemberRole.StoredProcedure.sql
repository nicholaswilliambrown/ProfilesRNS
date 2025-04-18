SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Display.Module].[Person.HasMemberRole]
	@Subject bigint,
	@Predicate bigint,
	@tagName varchar(max),
	@object bigint,
	@oValue nvarchar(max),
	@SessionID  UNIQUEIDENTIFIER = NULL,
	@json nvarchar(max) output
AS
BEGIN
	declare @SessionUserID int
	select @sessionUserID = UserID from [User.Session].Session where LogoutDate is null and sessionID=@sessionID and CreateDate > dateAdd(day, -1, getdate())

	declare @groups table (GroupID int, GroupName varchar(400), NodeID bigint, URL varchar(400))
	insert into @groups (GroupID, GroupName)
	select c.GroupID, c.GroupName from [Profile.Cache].Person a
		join [Profile.Data].[Group.Member] b
			on a.NodeID = @Subject
			and a.UserID = b.UserID
		join [Profile.Data].[Group.General] c
			on b.GroupID = c.GroupID
			and b.IsActive = 1
			and b.IsVisible = 1
			and c.EndDate > GETDATE()
		left join [Profile.Data].[Group.Manager] d
			on c.GroupID = d.GroupID and d.UserID = @SessionUserID
		where c.ViewSecurityGroup = -1 or d.UserID is not null or exists (select 1 from [Profile.Data].[Group.Admin] where UserId = @SessionUserID)

	update a set a.NodeID = b.NodeID from @groups a join [RDF.Stage].InternalNodeMap b on Class = 'http://xmlns.com/foaf/0.1/Group' and b.InternalID = cast(a.groupID as varchar(50))
	declare @relativeBasePath varchar(55)
	select @relativeBasePath = value from [Framework.].Parameter where ParameterID = 'relativeBasePath'

	update @groups set URL = @relativeBasePath + '/display/' + cast (nodeID as varchar(50))

	select @json = (
		select GroupName as Name, URL from @groups
		for json path, root('module_data'))
END
GO
