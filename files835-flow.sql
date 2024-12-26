--provider configuration
select * from FileWatcherRule where providerid = 2192
select * from MasterProviders
select * from ProviderLocations
select * from LockboxOwners
select * from ConfigValue where RefType != 'MasterProviders'

--application specific
select * from drv835anydocs where EDIVersion = '005010X221A1'

--document specific
-- inserted first
select FLSID, * from HpacFileLoad --specific to Hpac
select FLSID, * from FileLoadSummary
select FLSID, * from FileLoadDetail --almost history table
-- inserted second
select FLSID, LockBoxSummID, * from LockboxSummary
select LbxId, LockBoxSummID, ProviderId, * from LockboxDocumentTracking --one of the main table
select LbxId, * from AdOrgTiffs
select LbxId, * from ADOrgPdfs --don't really use it
-- inserted third
select LbxId, CLID, * from LockboxClaimDetail
select SLID, CLID, SLID, * from LockBoxServiceLineDetail