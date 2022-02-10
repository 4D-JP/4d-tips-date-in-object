//%attributes = {"invisible":true,"preemptive":"incapable"}
#DECLARE($json : Text; $params : Object; $signal : 4D:C1709.Signal)

If ($params.datesInsideObjects#Null:C1517)
	SET DATABASE PARAMETER:C642(Dates inside objects:K37:73; $params.datesInsideObjects)
End if 

If ($params.timesInsideObjects#Null:C1517)
	SET DATABASE PARAMETER:C642(Times inside objects:K37:90; $params.timesInsideObjects)
End if 

var $value : Variant

$value:=JSON Parse:C1218($json)

If (Not:C34(Process aborted:C672))
	
	Use ($signal)
		
		Case of 
			: (Value type:C1509($value)=Is object:K8:27)
				
				$signal.value:=OB Copy:C1225($value; ck shared:K85:29; $signal)
				
			: (Value type:C1509($value)=Is collection:K8:32)
				
				$signal.value:=$value.copy(ck shared:K85:29; $signal)
				
			Else 
				
				$signal.value:=$value
				
		End case 
		
		$signal.trigger()
		
	End use 
	
End if 

KILL WORKER:C1390