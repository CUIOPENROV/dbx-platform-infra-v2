##################################
#Error Checking Functions and Variables START
##################################
isFatal=false           # Used in the Script body to flag an error as Fatal
set -o errtrace         # Enable the err trap, code will get called when an error is detected
trap error_exit $? ERR  # (Needs clarification) This takes the error from ERR and passes it into error_exit
trap finish EXIT        # Enable the EXIT trap, code will print time taken for the script
start=$(date +%s)

#Exits the init script startup if the error is fatal
function error_exit()
{
    if [[ $isFatal = true  ||  $2 = true ]]; then
        echo "certification setup: ${1:-"Unknown Error"}" 1>&2
        exit 1
    fi
}

#Logs the excution time of the function
function finish {
    duration=$[$(date +%s) - ${start}]
    execution_time=`printf "%.2f seconds" $duration`
    echo "certification setup Execution Time: $execution_time"
}
##################################
#Error Checking Functions and Variables END
##################################
#Script body
#########################
### Update Certificates, to use capital one cert authority ###
#########################
function install_certs(){
cat <<EOF > /usr/local/share/ca-certificates/cap1.crt
-----BEGIN CERTIFICATE-----
MIIDyzCCArOgAwIBAgIEVgYUPTANBgkqhkiG9w0BAQsFADAjMQswCQYDVQQGEwJV
UzEUMBIGA1UEChMLQ2FwaXRhbCBPbmUwHhcNMTUxMTA2MjA0MjAxWhcNMzUxMTA2
MjExMjAxWjAjMQswCQYDVQQGEwJVUzEUMBIGA1UEChMLQ2FwaXRhbCBPbmUwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGOmMyD1fHpwu7DQKqGZNL5kIw
0IWAvsNuj14vaILRCRjj1C4Ef/91Y3B/jA4qTFkbA0OvBl9PNwRlFcRaFTl1GWWp
ra4C2GCuwby2JkrTZRPQ/qbR+htY1eDI5aMeqlqqz7rYV9gQccrvLyKCsaU2gR5o
/tooj/K1+rDhNM5+9Muu6RgkqYDyhj/4WH0Qq4Iv2FBzUktygPkBzT7VZdAE1VaZ
gij+eQ49+pJVgkVmYXyd4qYEvT6XkcpkmD0YjPCexDdvGjStDgZULShL8SIbEGuW
82tGcqb4BL2CpKGfOVkG/e3mLnbUe+PXOAjYZERzmyGa9KHVbaOO1GkxjkddAgMB
AAGjggEFMIIBATARBglghkgBhvhCAQEEBAMCAAcwRQYDVR0fBD4wPDA6oDigNqQ0
MDIxCzAJBgNVBAYTAlVTMRQwEgYDVQQKEwtDYXBpdGFsIE9uZTENMAsGA1UEAxME
Q1JMMTArBgNVHRAEJDAigA8yMDE1MTEwNjIwNDIwMVqBDzIwMzUxMTA2MjExMjAx
WjALBgNVHQ8EBAMCAQYwHwYDVR0jBBgwFoAU2QZQJCILUfbaoNK+g0fabvYq7QMw
HQYDVR0OBBYEFNkGUCQiC1H22qDSvoNH2m72Ku0DMAwGA1UdEwQFMAMBAf8wHQYJ
KoZIhvZ9B0EABBAwDhsIVjguMTo0LjADAgSQMA0GCSqGSIb3DQEBCwUAA4IBAQCb
9nyvSJmai8bFUqd/qMVsed/Nykb9Ij+vBcnrFfB5B/gPr1vRnMRu6a9gx3ILC/d4
VUmFYzOVL7p5Htcr6WhSPd7Bmniu87orSE3OCI8IGS7sEG6T1fdOxLxqS1npJY9r
dQokrDRr+2GDTZQCg9Y5iQzVOQOrTXvGInKaTRYPiQHNnFdcFFA5E/tcnxzANgZE
o09ARE7CwH46exhkvf4dAkI5bET1nsClC6ACwC2fDdsKVMfkRFGOtIv/2vafVje1
fnIeeAYevRzlB+E1IghSTS8u68GlFam07RTv0UPGPfH0Mqv+I/yNQ7Gof923oh5E
FaYkE8Ta/m2nfPQ6FnaG
-----END CERTIFICATE-----
EOF

cat <<EOF > /usr/local/share/ca-certificates/cap3.crt
-----BEGIN CERTIFICATE-----
MIID3DCCAsSgAwIBAgIEXWBGLzANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJV
UzEXMBUGA1UEChMOQ2FwaXRhbCBPbmUgRzIxIDAeBgNVBAsTF0NlcnRpZmljYXRl
IEF1dGhvcml0aWVzMR8wHQYDVQQDExZDYXBpdGFsIE9uZSBHMiBSb290IENBMB4X
DTE5MDgyMzE5MzE1MVoXDTM2MTEyMzIwMDE1MVowaTELMAkGA1UEBhMCVVMxFzAV
BgNVBAoTDkNhcGl0YWwgT25lIEcyMSAwHgYDVQQLExdDZXJ0aWZpY2F0ZSBBdXRo
b3JpdGllczEfMB0GA1UEAxMWQ2FwaXRhbCBPbmUgRzIgUm9vdCBDQTCCASIwDQYJ
KoZIhvcNAQEBBQADggEPADCCAQoCggEBAKJREDWpKFFUtweIpX2A/0TRtv7J7tvc
bgtDOIVLX7HE6Y6vIS21FBEp5GEOnSKSdtEw95RRB9AyhtJ9MdqX4KRYdvgjtSyA
YgtufcCU0QBaP3eRhs5qBodny10miKdPIcgTFfEvPUHVOaW8Sz8Hq3HUdVuJX/3B
pH45bFiMocPhuMtz9HyGfKOL6bUhJeuYKCLJUc23IKU0D64x3msxNPg+HbA709az
9DO1Jtx0WNEt03MmzggC58x5E2BTsVj2XYl7VyNosrffHb6B/sTorznD4ZFzuwG+
vlP0qYf/OnWTIIwscDKHk7mUM+i7CGZVhtVfeisf4gtx0xPteRvIcRsCAwEAAaOB
izCBiDArBgNVHRAEJDAigA8yMDE5MDgyMzE5MzE1MVqBDzIwMzYxMTIzMjAwMTUx
WjALBgNVHQ8EBAMCAQYwHwYDVR0jBBgwFoAUSb+4c5HFa4JGg04Mm3GSZ+A5bHsw
HQYDVR0OBBYEFEm/uHORxWuCRoNODJtxkmfgOWx7MAwGA1UdEwQFMAMBAf8wDQYJ
KoZIhvcNAQELBQADggEBAG42ke5nVMvDAsB1LrsCVRabjWMxsE2icWCGBNpnhD8A
0IB5dCoKOlWihc/1845fLbCcjhf7MGm6F88n4hKNIJEQYS8gZW87HmD55JgOZI1K
m3yQ120tfmA5zkwl2WNMPtkpSAUjk3fE2/ZON4rmgC4KBNCsTzUx80yR8e4UJJXv
7R5k1jXpjB6SdztbT5mJYx9K9/1N7l9mOcQrCYrsjzXr1xr317sSJkoksqQGqmFL
BaohUojUqFsTZc/0pzivl46WdYh7S2yApptAh2W4F9nR8WM2ACcfVKIB6CBg44Cw
9zEZaKzwolhaEVmXdbLDAlgXhiCLyO/6R3yoiRa51wk=
-----END CERTIFICATE-----
EOF

cat <<EOF > /usr/local/share/ca-certificates/cap4.crt
-----BEGIN CERTIFICATE-----
MIIFFzCCA/+gAwIBAgIEXxAxyzANBgkqhkiG9w0BAQsFADBpMQswCQYDVQQGEwJV
UzEXMBUGA1UEChMOQ2FwaXRhbCBPbmUgRzIxIDAeBgNVBAsTF0NlcnRpZmljYXRl
IEF1dGhvcml0aWVzMR8wHQYDVQQDExZDYXBpdGFsIE9uZSBHMiBSb290IENBMB4X
DTIwMDgxODE4MzQzMVoXDTM2MTAzMTAwMDAwMFowdjELMAkGA1UEBhMCVVMxFzAV
BgNVBAoTDkNhcGl0YWwgT25lIEcyMSAwHgYDVQQLExdDZXJ0aWZpY2F0ZSBBdXRo
b3JpdGllczEsMCoGA1UEAxMjQ3liZXIgQ29yZSBTZXJ2aWNlcyBVc2VyIElzc3Vp
bmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvIikv+Jv6dCDt
FyDaq9RIejANmNuahh4fKY8W2+cHcHNQLgTldyjSqilrKvAqMxJLcYVG9PaCECdv
WBEPd02PpHSBvQmWSolpeChEEyABuW1qMO4hv0LOFgEg9UJ9RPc2zVw5zPC0qDMy
dR4mB9gWwOQWF6MiI/pU6kR4YUvDpc/RX5kj621aOanveduJ+iwjuurkhbrb3V0b
uMVwMss1AVlzlyd8SgApEQhHIVHMKAIcWAPISU6pWsGTgY3jA9jClN0d2RQ4em0V
rqwQHtPof2Q4P2OWX5K+ZsjHkeK9bhAsR62bGPbgU0LKQKAQmgR/axQyZhrGiLkT
h+q83FuRAgMBAAGjggG4MIIBtDAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgw
BgEB/wIBADBhBggrBgEFBQcBAQRVMFMwUQYIKwYBBQUHMAGGRWh0dHA6Ly9lbnRy
dXN0Y3JsLmNsb3VkLmNhcGl0YWxvbmUuY29tL0FJQS9DZXJ0SXNzdWVkdG9DMUcy
Um9vdENBLnA3YzCBzwYDVR0fBIHHMIHEMD+gPaA7hjlodHRwOi8vZW50cnVzdGNy
bC5jbG91ZC5jYXBpdGFsb25lLmNvbS9DUkwvQzFHMlJvb3RDQS5jcmwwgYCgfqB8
pHoweDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkNhcGl0YWwgT25lIEcyMSAwHgYD
VQQLExdDZXJ0aWZpY2F0ZSBBdXRob3JpdGllczEfMB0GA1UEAxMWQ2FwaXRhbCBP
bmUgRzIgUm9vdCBDQTENMAsGA1UEAxMEQ1JMMTAfBgNVHSMEGDAWgBRJv7hzkcVr
gkaDTgybcZJn4DlsezAdBgNVHQ4EFgQU9BlD4KqqjwRVPwHZw5XAom2P6CgwGQYJ
KoZIhvZ9B0EABAwwChsEVjguMwMCAIEwDQYJKoZIhvcNAQELBQADggEBAEP3nm+k
WXKNBLJYo2jqYvgrjFAUvFi6g/vzd/AtI9LTwcEgQwcihYBwaUfJwUqDOnNrLV9M
sriGOVvkkqIyIGUy3iwTOcW0/a7vrvHBA9uHJEXtC9R58KXV1PscJSWplXNUCmhU
XwN+XGigKP4qQGg/InwJEAr1BLG//fLA1uWibOaYKDCY7FExUU+dtq+588992uA6
ID76IzfiqlmFeK0X8gHyCa0P0/SiaZ/4C92z6rcgFprBKJ/zrnak/R+pFPCge1B2
qc1i5e1hDNLRSeIaFDT509y0xwSBmOd8BKS5PdPOC2OTJAG2dR6omU/5ZnfQxGsr
/0Ay62S3TkLbRsA=
-----END CERTIFICATE-----
EOF

update-ca-certificates >/dev/null 2>&1

JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
KEYSTORE="$JAVA_HOME/lib/security/cacerts"

keytool -import -trustcacerts -alias C1-CA   -keystore $KEYSTORE   -file /etc/ssl/certs/cap1.pem   -storepass changeit   -noprompt >/dev/null 2>&1
keytool -import -trustcacerts -alias C2-CA   -keystore $KEYSTORE   -file /etc/ssl/certs/cap2.pem   -storepass changeit   -noprompt >/dev/null 2>&1
keytool -import -trustcacerts -alias C2-CA   -keystore $KEYSTORE   -file /etc/ssl/certs/cap3.pem   -storepass changeit   -noprompt >/dev/null 2>&1
keytool -import -trustcacerts -alias C2-CA   -keystore $KEYSTORE   -file /etc/ssl/certs/cap4.pem   -storepass changeit   -noprompt >/dev/null 2>&1

echo "export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" >> /databricks/spark/conf/spark-env.sh
cat /databricks/spark/conf/spark-env.sh
echo "CERTS_Installed"
}

install_certs