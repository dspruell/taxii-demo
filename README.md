# taxii-demo
A testing setup for a TAXII server and client.

This demo uses a small sample of published STIX bundles from CISA
(https://www.cisa.gov/).

## Setup
Requirements:

- curl
- Python 3

To set up and start the server, run this from the current directory:

    ./opentaxii-setup.sh

This will create a Python virtual environment and install the OpenTAXII
server and Cabby TAXII client. It sets up a simple demo configuration in
OpenTAXII. It then downloads sample STIX bundles and starts the OpenTAXII
development server.

After the server is started and running, open another shell in the same
directory. The following file contains a number of Cabby client commands that
can be run to demonstrate using the TAXII server:

1. Sending a Discovery request to identify available TAXII services.
2. Requesting a list of available collections.
3. Pushing the sample STIX bundles to the server, loading them into the
   configured collection.
4. Polling the remote collection from the server, pulling the uploaded STIX
   bundles down to the client.

