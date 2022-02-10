Function parse($json : Text; $datesInsideObjects : Integer; $timesInsideObjects : Integer)->$value : Variant
	
	$params:=New object:C1471
	$signal:=New signal:C1641
	
	If (Count parameters:C259>1)
		$params.datesInsideObjects:=$datesInsideObjects
	End if 
	
	If (Count parameters:C259>2)
		$params.timesInsideObjects:=$timesInsideObjects
	End if 
	
	CALL WORKER:C1389("JSON"; "parse"; $json; $params; $signal)
	
	$signal.wait()
	
	$value:=$signal.value