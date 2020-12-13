check=`curl -i  http://18.159.195.152:200 | grep -c "HTTP/1.1 200 "`
if [ $check -eq 1 ] 
then
echo "test success"
else 
exit 1
fi
