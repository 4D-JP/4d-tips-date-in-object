//%attributes = {"preemptive":"capable"}
$JSON:=JSON

$o:=$JSON.parse("{\"code\":\"9999-88-66\"}"; String type without time zone:K37:86)

ALERT:C41(JSON Stringify:C1217($o; *))