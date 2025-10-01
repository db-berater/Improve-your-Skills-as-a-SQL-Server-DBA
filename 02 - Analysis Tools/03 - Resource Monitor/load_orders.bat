ECHO OFF
(
	start "Machine 1" /b "ostress.exe" -E -SSQLServer -Q"EXEC dbo.load_orders @order_year = 2010;" -ddemo_db -r1 -q -oT:\temp\machine01
	start "Machine 2" /b "ostress.exe" -E -SSQLServer -Q"EXEC dbo.load_orders @order_year = 2011;" -ddemo_db -r1 -q -oT:\temp\machine02
	start "Machine 3" /b "ostress.exe" -E -SSQLServer -Q"EXEC dbo.load_orders @order_year = 2012;" -ddemo_db -r1 -q -oT:\temp\machine03
	start "Machine 4" /b "ostress.exe" -E -SSQLServer -Q"EXEC dbo.load_orders @order_year = 2013;" -ddemo_db -r1 -q -oT:\temp\machine04
)