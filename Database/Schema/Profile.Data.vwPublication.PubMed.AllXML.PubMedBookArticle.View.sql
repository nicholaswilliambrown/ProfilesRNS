SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [Profile.Data].[vwPublication.PubMed.AllXML.PubMedBookArticle]
as
		select pmid, 
			'PubMedBookDocument' HmsPubCategory,
			nref.value('Book[1]/BookTitle[1]','varchar(2000)') PubTitle, 
			nref.value('ArticleTitle[1]','varchar(2000)') ArticleTitle,
			nref.value('Book[1]/Publisher[1]/PublisherLocation[1]','varchar(60)') PlaceOfPub, 
			nref.value('Book[1]/Publisher[1]/PublisherName[1]','varchar(255)') Publisher, 
			cast(isnull(nref.value('Book[1]/PubDate[1]/Year[1]','varchar(4)'), '1900') + '-' + isnull(nref.value('Book[1]/PubDate[1]/Month[1]','varchar(2)'), '01') + '-' + isnull(nref.value('Book[1]/PubDate[1]/Day[1]','varchar(2)'), '01') as DATETIME) PublicationDT
		from [Profile.Data].[Publication.PubMed.AllXML] cross apply x.nodes('//PubmedBookArticle/BookDocument') as R(nref)
GO
