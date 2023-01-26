# Startup and Shutdown Scripts for DocPath Products

This is a complete example about how to deploy all the DocPath products sequentally. This scripts will try to starts all the products and verify they are correctly configured, if not, will stop them to avoid further error due to misconfiguration, these are the steps:
- starts the selected products individually.
- checks if the product is started successfully using their healthcheck endpoint.
- if is started, continues to the next product.
- if is not started, stops all products and give and error code.

## Prerequisites

The product that will be started, must be installed and activated successfully.

## Steps
To configure and execute the script, follow the steps as indicated below:

- Open the script with a text editor and add the path where the products are installed (`<product>Path` keys). Otherwise, the script will understand the product is not installed and will not try to start it. 
- If you want to use a JAVA JRE that is not the default in the system, modify the keys `<product_name>JREPath`. If these keys are empty, the script will execute "java -jar product", if not, it will execute the JRE in the selected path.
Assign privilegies to execute the script if required.
- Start it:
  - Type in Windows services_startup_windows.bat 
  - or type in Linux services_startup_windows.sh

## Product Versions

The following scripts are optimized for:
- DocPath Cache Service 6.5.0
- DocPath Resources on Demand 6.11.0
