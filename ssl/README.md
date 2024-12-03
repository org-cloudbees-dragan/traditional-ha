* https://www.jenkins.io/doc/book/system-administration/reverse-proxy-configuration-with-jenkins/reverse-proxy-configuration-haproxy/
* https://www.jenkins.io/doc/book/installing/initial-settings/#configuring-http

# Java SSL Properties

* javax.net.ssl.keyStore- Location of the Java keystore file containing an application process's own certificate and private key. On Windows, the specified pathname must use forward slashes, /, in place of backslashes.
* javax.net.ssl.keyStorePassword - Password to access the private key from the keystore file specified by javax.net.ssl.keyStore. This password is used twice: To unlock the keystore file (store password), and To decrypt the private key stored in the keystore (key password).
* javax.net.ssl.trustStore - Location of the Java keystore file containing the collection of CA certificates trusted by this application process (trust store). On Windows, the specified pathname must use forward slashes, /, in place of backslashes, \.*
If a trust store location is not specified using this property, the SunJSSE implementation searches for and uses a keystore file in the following locations (in order):

```
$JAVA_HOME/lib/security/jssecacerts
$JAVA_HOME/lib/security/cacerts
```
+ javax.net.ssl.trustStorePassword - Password to unlock the keystore file (store password) specified by javax.net.ssl.trustStore.
* javax.net.ssl.trustStoreType - (Optional) For Java keystore file format, this property has the value jks (or JKS). You do not normally specify this property, because its default value is already jks.
* javax.net.debug - To switch on logging for the SSL/TLS layer, set this property to ssl.
> -Djavax.net.debug=all or  -Djavax.net.debug=ssl

# Keystore vs. Truststore 

In Java, **Truststore** and **Keystore** are both used to manage certificates and keys, but they serve different purposes. Here's a detailed explanation of their differences:

---

### **1. Keystore**
- **Purpose:**  
  A **keystore** stores the private key and its associated certificate chain. It is primarily used to identify the **server** or **client** in SSL/TLS communication.

- **Contents:**
  - **Private Key:** Used to establish identity and decrypt data during SSL handshakes.
  - **Certificate Chain:** Verifies the authenticity of the private key.
  - **Self-signed or CA-signed Certificates:** Associated with the private key.

- **Common Use Cases:**
  - When a Java application acts as a **server**, the keystore is used to present its certificate to clients during the SSL handshake.
  - When a Java application acts as a **client** requiring mutual authentication, it provides its certificate to the server.

- **Default Java Keystore File:**
  - Typically in **JKS** format (`.jks`), though PKCS#12 (`.p12`) is also supported in modern Java.
  - Location is often specified using the `javax.net.ssl.keyStore` system property.

- **Example Configuration:**
  ```bash
  -Djavax.net.ssl.keyStore=/path/to/keystore.jks
  -Djavax.net.ssl.keyStorePassword=changeit
  ```

---

### **2. Truststore**
- **Purpose:**  
  A **truststore** contains trusted certificates, which are used to verify the identity of the **remote server** (or client in mutual authentication).

- **Contents:**
  - **Public Certificates** (only, no private keys): Typically those issued by Certificate Authorities (CAs) or self-signed certificates that the application trusts.
  - Acts as a repository of **trusted entities**.

- **Common Use Cases:**
  - When a Java application acts as a **client**, the truststore verifies the server's certificate during the SSL handshake.
  - When a Java application acts as a **server**, it can use the truststore to verify client certificates in **mutual authentication** scenarios.

- **Default Java Truststore File:**
  - Java comes with a default truststore (`cacerts`) in the JRE, located in the `lib/security` directory.
  - The default password for `cacerts` is `changeit`.
  - Location is specified using the `javax.net.ssl.trustStore` system property.

- **Example Configuration:**
  ```bash
  -Djavax.net.ssl.trustStore=/path/to/truststore.jks
  -Djavax.net.ssl.trustStorePassword=changeit
  ```

---

### **Key Differences**

| Feature              | Keystore                          | Truststore                        |
|----------------------|-----------------------------------|-----------------------------------|
| **Purpose**          | Identify the application (server/client) | Verify the identity of others (server/client) |
| **Contents**         | Private keys, associated certificate chains | Trusted certificates (public keys) |
| **Used By**          | Servers and clients (for their own identity) | Clients and servers (to trust others) |
| **Contains Private Keys?** | Yes                               | No                                |
| **Default File**     | No default; user-specified         | `cacerts` (default truststore)    |
| **System Property**  | `javax.net.ssl.keyStore`           | `javax.net.ssl.trustStore`        |

---

### **When Both Are Used**
In scenarios like **mutual TLS authentication**, both keystore and truststore are required:
- The **keystore** is used to present the application's own identity (certificate and private key).
- The **truststore** is used to verify the remote entity's identity (via its certificate).

---

### **Practical Example**
#### Server-Side Example (HTTPS Server):
- **Keystore:** Stores the server's SSL certificate and private key to identify itself to clients.
- **Truststore:** If mutual authentication is enabled, it contains the client certificates the server trusts.

#### Client-Side Example (Java Client using SSL):
- **Keystore:** If the client needs to authenticate to the server, it provides its own certificate and private key from the keystore.
- **Truststore:** Verifies the server's certificate.

Let me know if you'd like to see specific commands or code examples for managing these stores!

# Certificates

These files are commonly associated with SSL/TLS certificates and keys. Here's what each type typically represents:

---

### **1. `jenkins.crt` (Certificate)**
- **Description:** This is a certificate file, typically in **X.509** format. It contains the public key along with details about the entity it certifies (e.g., domain name, organization) and is issued by a Certificate Authority (CA) or self-signed.
- **Usage:** Installed on a server (e.g., Jenkins) to enable HTTPS, allowing secure communication between clients and the server.

---

### **2. `jenkins.csr` (Certificate Signing Request)**
- **Description:** A CSR file is a request to a Certificate Authority to issue a certificate. It contains the server's public key and the server's identifying information (e.g., domain, organization name) but no private key.
- **Usage:** Used to generate the `jenkins.crt` by submitting it to a Certificate Authority.

---

### **3. `jenkins.jks` (Java KeyStore)**
- **Description:** A JKS is a Java-specific keystore format that can store:
    - Private keys
    - Public certificates
    - Certificate chains
- **File Format:** Binary
- **Usage:** Typically used in Java applications (like Jenkins) to store and manage SSL certificates and private keys.
- **Access:** Managed with tools like `keytool`.

---

### **4. `jenkins.key` (Private Key)**
- **Description:** This file contains the private key associated with the SSL certificate. The private key is critical for the SSL handshake and must be kept secure.
- **Usage:** Paired with the `jenkins.crt` to establish secure connections.
- **Important:** Never share this file publicly.

---

### **5. `jenkins.p12` (PKCS#12 File)**
- **Description:** A `.p12` file (or `.pfx`) is a portable format for storing:
    - Private keys
    - Certificates
    - Certificate chains
- **File Format:** Binary (based on the PKCS#12 standard).
- **Usage:**
    - Used in applications that support PKCS#12 (e.g., browsers, some servers).
    - Can be converted into `.jks`, `.pem`, or other formats.

---

### **6. `jenkins.pem` (Privacy-Enhanced Mail)**
- **Description:** A `.pem` file is a Base64-encoded file used to store:
    - Certificates
    - Private keys
    - Public keys
- **File Format:** Plaintext, enclosed in `-----BEGIN-----` and `-----END-----` tags.
- **Usage:**
    - `jenkins.pem` might contain the certificate (`jenkins.crt`), private key (`jenkins.key`), or both.
    - Widely used in non-Java environments or tools like `nginx` and `Apache`.

---

### **How They Work Together in Jenkins**
- **CSR and Certificate (`.csr`, `.crt`):** The `jenkins.csr` is used to generate `jenkins.crt`.
- **Private Key (`.key`):** The `jenkins.key` is paired with `jenkins.crt` for HTTPS.
- **Java KeyStore (`.jks`):** A `.jks` file bundles the private key and certificate for use in Jenkins.
- **PKCS#12 (`.p12`):** Portable alternative to `.jks`, convertible if needed.
- **PEM (`.pem`):** Can store certificates or keys for cross-platform compatibility.

---

### **Conversion Examples**
1. **Convert `.p12` to `.jks`:**
   ```bash
   keytool -importkeystore \
       -srckeystore jenkins.p12 -srcstoretype pkcs12 \
       -destkeystore jenkins.jks -deststoretype jks
   ```

2. **Extract `.pem` from `.crt` and `.key`:**
   ```bash
   cat jenkins.crt jenkins.key > jenkins.pem
   ```

3. **Convert `.pem` to `.p12`:**
   ```bash
   openssl pkcs12 -export -in jenkins.pem -out jenkins.p12 -name "JenkinsCert"
   ```

Let me know if you'd like detailed steps for managing these files in Jenkins!

