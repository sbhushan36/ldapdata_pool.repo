while read line
do

# First LDAP host details - 
ldapsearch -T1 -h LDAP_HOSTNAME_IP -D "cn=directory manager" -w 'PASSWORD' -b 'dc=nic,dc=in' -LLL uid=$line sn cn title givenname displayname mailEquivalentAddress | egrep -i 'sn:|cn:|title:|givenname:|displayname:|mailEquivalentAddress:' | grep [a-z] > sun.txt ; sed -i -e 's/mailEquivalentAddress/zimbraMailAlias/g' sun.txt ; sort sun.txt > sun1.txt                        

# 2nd LDAP host details -  
ldapsearch -LLL -x -h 2LDAP_HOSTNAME_IP -b 'ou=people,dc=nic,dc=in' -D 'uid=zimbra,cn=admins,cn=zimbra' -w 2LDAP_PASSWORD uid=$line sn cn title givenname displayname zimbramailalias | grep -v dn: > zimbra.txt ; sort zimbra.txt > zimbra1.txt

sed -e '/^$/d' zimbra1.txt > zim1.txt
diff sun1.txt zim1.txt  

if [ "$?" -eq 0 ];
then
echo eq

else
echo not eq

ldapsearch -LLL -x -h 2LDAP_HOSTNAME_IP -b 'ou=people,dc=nic,dc=in' -D 'uid=zimbra,cn=admins,cn=zimbra' -w 2LDAP_PASSWORD uid=$line uid | grep dn: > change.txt

echo changetype: modify >>change.txt
echo replace: cn >>change.txt

cat sun1.txt | grep cn: >> change.txt
echo - >> change.txt
echo replace: sn >>change.txt

cat sun1.txt | grep sn: >> change.txt
echo - >> change.txt
echo replace: title >>change.txt

cat sun1.txt | grep title: >> change.txt
echo - >> change.txt
echo replace: givenname >>change.txt

cat sun1.txt | grep givenname: >> change.txt
echo - >> change.txt
echo replace: displayname >>change.txt

cat sun1.txt | grep displayname: >> change.txt

# Use ldapModify to edit ldap - 
ldapmodify -v -h LDAP_HOSTNAME_IP -D 'uid=zimbra,cn=admins,cn=zimbra' -w LDAP_PASSWORD -f change.txt

# Or use below if required - 
#while read line1
#do
#attr=`echo $line1 | awk -F: '{print $1}'`
#val=`echo $line1 | awk -F: '{print $2}'`
#echo $attr $val
#echo zmprov ma $line $attr \"$val\"
#done < "change.txt"

fi
grep zimbraMailAlias sun.txt > sun2.txt
grep zimbraMailAlias zimbra.txt > zimbra2.txt

diff sun2.txt zimbra2.txt
     if [ "$?" -eq 0 ];
      then
       echo eq
       else
       echo not eq


ldapsearch -LLL -x -h LDAP_HOSTNAME_IP -b 'ou=people,dc=nic,dc=in' -D 'uid=zimbra,cn=admins,cn=zimbra' -w LDAP_PASSWORD uid=$line uid | grep dn: > aliasadd.txt
echo changetype: modify >>aliasadd.txt
echo add: zimbraMailAlias >>aliasadd.txt
fgrep -i -v -x -f zimbra2.txt sun2.txt >> aliasadd.txt

ldapmodify -v -h LDAP_HOSTNAME_IP -D 'uid=zimbra,cn=admins,cn=zimbra' -w LDAP_PASSWORD -f aliasadd.txt
fi
done < "user-bak"
#ldapmodify -v -h LDAP_HOSTNAME_IP -D 'uid=zimbra,cn=admins,cn=zimbra' -w LDAP_PASSWORD -f change.txt
