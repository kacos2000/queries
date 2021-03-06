-- Diagnostic ClipboardHistory
-- Included events:
-- 'Microsoft.Windows.ClipboardHistory.Service.CopyActionDetected_Compliant',
-- 'Microsoft.Windows.ClipboardHistory.Service.PasteActionDetected_Compliant',
-- 'Microsoft.Windows.ClipboardHistory.Service.AddItemActivity',
-- 'Microsoft.WindowsInternal.ComposableShell.Experiences.SuggestionUI.ClipboardHistoryChangeDetected',
-- 'Microsoft.WindowsInternal.ComposableShell.Experiences.SuggestionUI.ClipboardUpdateDetected'
--
-- from C:\ProgramData\Microsoft\Diagnosis\EventTranscript\EventTranscript.db
-- For more info visit https://github.com/rathbuna/EventTranscript.db-Research


SELECT

--Timestamp from db field
json_extract(events_persisted.payload,'$.time') as 'UTC TimeStamp',
-- Timestamp from json payload
datetime((timestamp - 116444736000000000)/10000000, 'unixepoch','localtime') as 'Local TimeStamp',
json_extract(events_persisted.payload,'$.ext.loc.tz') as 'TimeZome',
json_extract(events_persisted.payload,'$.ext.utc.seq') as 'seq',
json_extract(events_persisted.payload,'$.data.Origin') as 'Origin',

case json_extract(events_persisted.payload,'$.data.IsCurrentClipboardData') 
	when 1 then 'Yes'
	when 0 then 'No'
	end as 'Is Current',
producers.producer_id_text as 'Producer',

-- Actions
replace(replace(replace(replace(replace(full_event_name,'Microsoft.Windows.ClipboardHistory.Service.',''),'_Compliant',''),'Detected',''),'Activity',''),'Microsoft.WindowsInternal.ComposableShell.Experiences.SuggestionUI.','') as 'Event',
coalesce(json_extract(events_persisted.payload,'$.data.sourceApplicationName'),json_extract(events_persisted.payload,'$.data.SourceApplicationName'),json_extract(events_persisted.payload,'$.data.AppExecutableName')) as 'Copy Source',
json_extract(events_persisted.payload,'$.data.targetApplicationName') as 'Paste Target',
json_extract(events_persisted.payload,'$.data.TargetProcessId') as 'Target pid',

-- JSON of copied items info
case  
	when json_extract(events_persisted.payload,'$.data.Formats') like '%Bitmap%' then 'Bitmap'
	when json_extract(events_persisted.payload,'$.data.Formats') like '%Text%' then 'Text'
	when json_extract(events_persisted.payload,'$.data.Formats') like '{}' then '--'
	when json_extract(events_persisted.payload,'$.data.Formats') like '%DropEffectFolderList%' then 'DropEffectFolderList'
	when json_extract(events_persisted.payload,'$.data.Formats') like '%Clipboard#MoveToScrap%' then 'MoveToScrap'
	else json_extract(events_persisted.payload,'$.data.Formats')
end as 'Clip Type',
json_extract(events_persisted.payload,'$.data.ItemDataCreationStatus') as 'Creation Status',

-- Appear to link clipboard events
json_extract(events_persisted.payload,'$.data.wilActivity.threadId') as 'ThreadId',
trim(json_extract(events_persisted.payload,'$.ext.protocol.ticketKeys'),'"[]"') as 'ticketKeys',
trim(coalesce(json_extract(events_persisted.payload,'$.data.ItemId'),json_extract(events_persisted.payload,'$.data.itemId')),'{}') as'ItemId',

-- Local, MS or AAD account 
trim(json_extract(events_persisted.payload,'$.ext.user.localId'),'m:') as 'UserId',
sid as 'User SID',


-- Device class (same as the type used in ActivitiesCache.db
TRIM(json_extract(events_persisted.payload,'$.ext.device.deviceClass'),'Windows.') as 'Device Class',
-- json_extract(events_persisted.payload,'$.ext.device.localId') as 'localId',

-- Device info from registry
json_extract(events_persisted.payload,'$.ext.os.name') as 'OS',
json_extract(events_persisted.payload,'$.ext.protocol.devMake') as 'Device Make',
json_extract(events_persisted.payload,'$.ext.protocol.devModel') as 'Device Model',
logging_binary_name

from events_persisted 
join producers on producers.producer_id = events_persisted.producer_id
-- include events:
where events_persisted.full_event_name in 
('Microsoft.Windows.ClipboardHistory.Service.CopyActionDetected_Compliant',
'Microsoft.Windows.ClipboardHistory.Service.PasteActionDetected_Compliant',
'Microsoft.Windows.ClipboardHistory.Service.AddItemActivity',
'Microsoft.WindowsInternal.ComposableShell.Experiences.SuggestionUI.ClipboardHistoryChangeDetected',
'Microsoft.WindowsInternal.ComposableShell.Experiences.SuggestionUI.ClipboardUpdateDetected')

 -- Sort by event sequence number descending (newest first)
order by cast(seq as integer) desc


