exp_date=$(date -d "$(openssl x509 -enddate -noout -in ./cert/fullchain.crt | awk -F = '{print $2}')" '+%s')
now=$(date '+%s')
echo "EXPIRE AT: ${exp_date}"
echo "NOW: ${now}"
test $exp_date -gt $now