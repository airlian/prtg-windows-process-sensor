# Windows Process Monitoring Script

This script monitors a specified Windows process and sends relevant data to a PRTG Probe using an HTTP Push Data Advanced Sensor. The script is intended to be deployed on the monitored host and executed periodically via Task Scheduler.

## Requirements

- Windows PowerShell
- PRTG Network Monitor with HTTP Push Data Advanced Sensor configured

## Usage

### Setting Up the PRTG Sensor

Before running the script with the full parameters, ensure you have configured the **HTTP Push Data Advanced Sensor** in PRTG:

1. Sensor Name: Define the sensor's name.
2. TLS Settings / Port
3. Identification Token: Set a unique token to identify the sensor.
3. Time Threshold (Minutes): Define the duration PRTG should wait for data before reporting an error.

### Parameters

The script requires two parameters:

1. **Process Name**: The name of the process to monitor, without the file extension. For example, to monitor `chrome.exe`, use `chrome` as the parameter.
2. **PRTG Probe API URL**: The URL for the PRTG Probe's API corresponding to an HTTP Push Data Advanced Sensor. This should be in the format `http://<probe_host>:<port>/<token>`.



### Examples

#### Testing Locally

You can start by testing the script with a single parameter to ensure it captures the correct data. Open a command prompt or PowerShell window and run:

```powershell
PS C:\Users\airli> .\WindowsProcess.ps1 chrome
```

##### Sample Output:

```
Logical Processors: 16
Process Name: chrome
HTTP POST Payload: <PRTG>
<Result><Channel>Instances</Channel><Value>15</Value></Result>
<Result><Channel>Handles</Channel><Value>9315</Value></Result>
<Result><Channel>Threads</Channel><Value>306</Value></Result>
<Result><Channel>CPU Usage (Total)</Channel><Value>0</Value><Unit>Percent</Unit></Result>
<Result><Channel>CPU Usage (average per Instance)</Channel><Value>0</Value><Unit>Percent</Unit></Result>
<Result><Channel>Working Set</Channel><Value>1897738240</Value><Unit>BytesMemory</Unit></Result>
<Result><Channel>Private Bytes</Channel><Value>2179698688</Value><Unit>BytesMemory</Unit></Result>
</PRTG>
```

This output shows details such as the number of instances, CPU usage, and memory consumption, formatted to match PRTG’s expected input.

#### Full Execution

Once the local test confirms the script's functionality, you can proceed with sending the data to the PRTG Probe. Run the script with both parameters:

```powershell
PS C:\Users\airli> .\WindowsProcess.ps1 chrome http://localhost:5050/chrome
```

##### Sample Output:

```
Logical Processors: 16
Process Name: chrome
Probe URL: http://localhost:5050/chrome
HTTP POST Payload: <PRTG>
<Result><Channel>Instances</Channel><Value>15</Value></Result>
<Result><Channel>Handles</Channel><Value>9339</Value></Result>
<Result><Channel>Threads</Channel><Value>307</Value></Result>
<Result><Channel>CPU Usage (Total)</Channel><Value>0</Value><Unit>Percent</Unit></Result>
<Result><Channel>CPU Usage (average per Instance)</Channel><Value>0</Value><Unit>Percent</Unit></Result>
<Result><Channel>Working Set</Channel><Value>1803931648</Value><Unit>BytesMemory</Unit></Result>
<Result><Channel>Private Bytes</Channel><Value>2192175104</Value><Unit>BytesMemory</Unit></Result>
</PRTG>

Probe Response: {"status":"Ok","Matching Sensors":"1"}
```

If Matching Sensors is 1, the probe is successfully receiving and recognizing the data. If it is 0, the probe is listening but has not yet matched the data to a configured sensor. This may take a few seconds; keep testing until you see Matching Sensors: 1.

### Deployment

Once tested, schedule the script to run at regular intervals using Task Scheduler to ensure continuous monitoring. If the script does not execute as expected, PRTG will report an error after the defined timeout.

### License

This project is licensed under the MIT License.
