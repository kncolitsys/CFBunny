REQUIREMENTS
----------------------------------------------------------
* ColdFusion MX 7.0.2 or above.
* Railo 3.1 or above	
	
INSTALLATION
----------------------------------------------------------
* Put cfbunny.cfc anywhere sensible and then create an instance 
of the component with your bunny credentials (serial number and api token). 
Ideally, the instance should be cached (e.g. in the App scope, or a ColdSpring singleton).

A rough example:

<cfset variables.bunny = CreateObject('component', 'path.to.cfbunny').init( mySerialNumber, myToken ) />

USAGE
----------------------------------------------------------
 
Presuming that you have an instance of the component named variables.bunny, you can use the component like so:

<cfscript>
	// sending instructions
	success = bunny.moveEars( leftEar=0, rightEar=16 ); // move the ears, valid positions are 0-16
	success = bunny.sendTtsMessage( 'This is a test', 'UK-Leonard' ); // send a text to speech message, optionally specifying the voice to use
	success = bunny.sendToSleep(); // send your bunny to sleep
	success = bunny.wakeUp(); // wake your bunny up
	success = bunny.doChoreography( '10,0,led,2,0,238,0,2,led,1,250,0,0,3,led,2,0,0,0' ); // choreography is a little finickity, see the online documentation
	
	// getting data
	voices = bunny.getSupportedVoices('UK'); // get the available text to speech voices, optionally filtering by country code. Returns an array of strings.
	friends = bunny.getFriends(); // gets an array of your bunny's friends
	blackList = bunny.getBlacklist(); // gets an array of blacklisted users
	inbox = bunny.getInboxMessages(); // gets an array of structs that represent your inbox
	timezone = bunny.getTimezone(); // gets the timezone set for the bunny
	sig = bunny.getSignature(); // get the signature set for the bunny
	name = bunny.getName(); // get the name of the bunny
	version = bunny.getVersion(); //get the version of the bunny (either V1, or V2 at present)
	languages = bunny.getLanguages(); // get an array of the registered languages for the bunny
	isSleeping = bunny.isSleeping(); // true or false, is the bunny sleeping? 
</cfscript>

There are some features of the documented API that have not been implemented. These are to do with message ids and the like - 
I could not find anywhere to reference these ids, the documentation appears to be misleading.

