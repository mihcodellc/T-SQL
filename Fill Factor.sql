about fillfactor change, is to avoid server to do heavy task when the index is full
but leaving space(reduce fillfactor) 
	Make the database larger --(which also makes their backups, restores, corruption checking, index rebuilds, etc all take longer)
	Make their memory smaller --(because each 8KB data page will have a percentage of empty space, and that space is cached in RAM as well)
	Make table scans take longer --(because more logical reads are involved)
		ref:https://www.brentozar.com/archive/2019/08/dba-training-plan-10-managing-index-fragmentation/

	Fill factor lets us leave empty space on every page for future updates.
	This instantly makes your:
	Database larger
	Memory smaller (because there’s less real data per page)
	Queries take longer
	Backups & DBCCs take longer
	Index rebuilds take longer
		ref: https://www.brentozar.com/blitz/fill-factor/
