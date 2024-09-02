CREATE PROCEDURE InsertFromSource
AS
BEGIN
    -- Insert new records from SourceUser to DestinationUser
    INSERT INTO DestinationUser (id, name, lastUpdated, isDeleted)
    SELECT su.id, su.name, su.lastUpdated, 0 -- Setting isDeleted to 0 (not deleted) by default
    FROM SourceUser su
    LEFT JOIN DestinationUser du ON su.id = du.id
    WHERE du.id IS NULL;
END;
GO


CREATE PROCEDURE UpdateFromSource
AS
BEGIN
    -- Update existing records in DestinationUser with updated data from SourceUser
    UPDATE du
    SET du.name = su.name,
        du.lastUpdated = su.lastUpdated,
        du.isDeleted = 0 -- Resetting isDeleted to 0 (not deleted) on update
    FROM DestinationUser du
    JOIN SourceUser su ON du.id = su.id
    WHERE su.lastUpdated > du.lastUpdated;
END;
GO


CREATE PROCEDURE SoftDeleteFromSource
    @deletedId INT
AS
BEGIN
    -- Soft delete the record in DestinationUser by setting isDeleted to 1
    UPDATE DestinationUser
    SET isDeleted = 1
    WHERE id = @deletedId;
END;
GO

CREATE TRIGGER trg_after_insert_sourceuser
ON SourceUser
AFTER INSERT
AS
BEGIN
    -- Call the InsertFromSource procedure
    EXEC InsertFromSource;
END;
GO

CREATE TRIGGER trg_after_update_sourceuser
ON SourceUser
AFTER UPDATE
AS
BEGIN
    -- Call the UpdateFromSource procedure
    EXEC UpdateFromSource;
END;
GO

CREATE TRIGGER trg_after_delete_sourceuser
ON SourceUser
AFTER DELETE
AS
BEGIN
    DECLARE @deletedId INT;

    -- Get the ID of the deleted record
    SELECT @deletedId = d.id FROM DELETED d;

    -- Call the SoftDeleteFromSource procedure
    EXEC SoftDeleteFromSource @deletedId;
END;
GO

