#!/bin/bash

source ./0-common.sh


#$ETCD_CERT_DIR
#$KUBERNETES_CERT_DIR

# Create ROOT CA

sudo mkdir -p $KUBERNETES_CERT_DIR
sudo chmod 0700 $KUBERNETES_CERT_DIR
sudo openssl req \
  -new -x509 -newkey rsa:4096 -nodes -extensions v3_ca -days 3650 \
  -subj "/O=Kubernetes/CN=Kubernetes CA" \
  -keyout $KUBERNETES_CA_KEY_PATH \
  -out $KUBERNETES_CA_CERT_PATH

#
# Generate ETCD certificates
#

# Create subjectAltName list for certificate request
i=1
for ip in ${CONTROLLER_PRIVATE_IPS[@]}; do
    if [ "x$IPS" == "x" ]; then
      IPS="IP.$i = $ip"
    else
      IPS="$IPS\nIP.$i = $ip"
    fi
    i=$(($i+1))
done

# Create certificate request configuration (to be used by openssl)
cat <<EOF > $ETCD_SERVER_CERTREQ_CONFIG
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
extendedKeyUsage = clientAuth,serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${CLUSTER_DOMAIN}
$(echo -e $IPS)
EOF

# Generate certificate sign request (to be signed by CA)
sudo openssl req -new \
  -newkey rsa:4096 \
  -nodes \
  -keyout $ETCD_SERVER_KEY_PATH \
  -out $ETCD_SERVER_CSR_PATH \
  -subj "/CN=etcd/O=etcd" \
  -config $ETCD_SERVER_CERTREQ_CONFIG

sudo openssl x509 -req \
  -in $ETCD_SERVER_CSR_PATH \
  -CA $KUBERNETES_CA_CERT_PATH \
  -CAkey $KUBERNETES_CA_KEY_PATH \
  -CAcreateserial \
  -extensions v3_req \
  -days 10000 \
  -out $ETCD_SERVER_CERT_PATH \
  -extfile $ETCD_SERVER_CERTREQ_CONFIG

exit

# COPY CERTIFICATES TO OTHER NODES
