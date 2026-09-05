-- Run only with Jellyfin stopped and its real data/data/jellyfin.db backed up.
.bail on
PRAGMA foreign_keys=ON;
BEGIN IMMEDIATE;
CREATE TEMP TABLE house AS
SELECT Id FROM BaseItems
WHERE ParentId='7E780226-D43E-E942-B0E5-6F665644A80D'
AND Type='MediaBrowser.Controller.Entities.TV.Episode'
AND Path LIKE '/mnt/media2/encodes/41df202e-e090-493c-aea9-38be8b93ba19/tv/aaee0f33-ec5c-418b-9dc6-ee23f14bc5e9/%.mkv';
CREATE TEMP TABLE guard (ok INTEGER CHECK(ok=1));
INSERT INTO guard SELECT count(*)=22 FROM house;
INSERT INTO guard SELECT count(*)=22 AND count(DISTINCT IndexNumber)=22
    AND min(IndexNumber)=1 AND max(IndexNumber)=22 AND min(ParentIndexNumber)=1 AND max(ParentIndexNumber)=1
    FROM BaseItems WHERE Id IN (SELECT Id FROM house);
INSERT INTO guard SELECT count(*)=0 FROM LinkedChildren
    WHERE ParentId IN (SELECT Id FROM house) AND ChildType=2 AND ChildId NOT IN (SELECT Id FROM house);
DELETE FROM LinkedChildren WHERE ParentId IN (SELECT Id FROM house) AND ChildType=2;
UPDATE BaseItems SET PrimaryVersionId=NULL,OwnerId=NULL,
    PresentationUniqueKey=replace(lower(Id),'-',''),
    Data=json_set(Data,'$.LocalAlternateVersions',json('[]'),'$.LinkedAlternateVersions',json('[]'))
WHERE Id IN (SELECT Id FROM house);
INSERT INTO guard SELECT count(*)=0 FROM pragma_foreign_key_check;
COMMIT;
SELECT 'House alternate links cleared',count(*) FROM house;
