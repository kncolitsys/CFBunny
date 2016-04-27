<cfcomponent output="false">
	
<!--- PROPERTIES AND CONSTANTS --->
	<cfscript>
		_setSerialNumber( "" );
		_setToken( "" );
		_setApiUrl( "http://api.nabaztag.com/vl/FR/api.jsp" );
		_setDefaultVoice( "" );
		_setupActions();
		_setupKnownErrors();
		
		this.ERROR_UNKNOWN = 101;
		this.ERROR_FROM_NABAZTAG = 102;
		this.ERROR_HTTP = 103;
	</cfscript>
	
<!--- CONSTRUCTOR --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="serialNumber" type="string" required="true" />
		<cfargument name="token" type="string" required="true" />
		<cfargument name="defaultVoice" type="string" required="false" default="heather22k" />
		
		<cfscript>
			_setSerialNumber( arguments.serialNumber );
			_setToken( arguments.token );
			_setDefaultVoice( arguments.defaultVoice );
			
			return this;
		</cfscript>
	</cffunction>

<!--- INSTRUCTION METHODS --->
	<cffunction name="sendTtsMessage" access="public" returntype="boolean" output="false">
		<cfargument name="message" type="string" required="true" />
		<cfargument name="voice" type="string" required="false" default="#_getDefaultVoice()#" />
		
		<cfscript>
			var params = StructNew();
			var response = "";
			
			params['tts'] = arguments.message;
			params['voice'] = arguments.voice;
			
			response = _serverCall( params=params );

			return _isResponseAsExpected ( response, 'TTSSENT' );
		</cfscript>
	</cffunction>

	<cffunction name="moveEars" access="public" returntype="boolean" output="false">
		<cfargument name="leftEar" type="numeric" required="false" hint="Position of the right ear between 0 and 16 (0 = ear vertical, 10 = ear horizontal)" />
		<cfargument name="rightEar" type="numeric" required="false" hint="Position of the right ear between 0 and 16 (0 = ear vertical, 10 = ear horizontal)" />
		
		<cfscript>
			var params = StructNew();
			var response = "";
			
			if(StructKeyExists(arguments, 'leftEar')){
				params['posleft'] = arguments.leftEar;
			}
			if(StructKeyExists(arguments, 'rightEar')){
				params['posright'] = arguments.rightEar;
			}
			
			response = _serverCall( params=params );
			
			return _isResponseAsExpected ( response, 'EARPOSITIONSENT' );
		</cfscript>
	</cffunction>

	<cffunction name="sendToSleep" access="public" returntype="boolean" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('SEND_TO_SLEEP') );
			return _isResponseAsExpected( response, 'COMMANDSENT' );
		</cfscript>
	</cffunction>
	
	<cffunction name="wakeUp" access="public" returntype="boolean" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('WAKE_UP') );
			return _isResponseAsExpected( response, 'COMMANDSENT' );
		</cfscript>
	</cffunction>

	<cffunction name="doChoreography" access="public" returntype="boolean" output="false">
		<cfargument name="choreography" type="string" required="true" hint="String detailing the choreography to perform. Please see the onlin API documentation. Todo: create some simpler util methods for choreography." />
		
		<cfscript>
			var params = StructNew();
			var response = "";
			
			params['chor'] = arguments.choreography;
		
			response = _serverCall( params=params );

			return _isResponseAsExpected ( response, 'CHORSENT' );
		</cfscript>
	</cffunction>

<!--- GETTING INFORMATION --->
	<cffunction name="getSupportedVoices" access="public" returntype="array" output="false">
		<cfargument name="languageFilter" type="string" required="false" hint="Two letter code, e.g. UK, US, FR, etc."/>
		
		<cfscript>
			var response = _serverCall( action=_getAction('GET_SUPPORTED_VOICES') );
			var voices = ArrayNew(1);
			var search = "";
			var i = 0;
						
			// search response xml for 'voices'
			search = XmlSearch( response, '/rsp/voice/@command' );
						
			// no voices, throw an error
			if(not ArrayLen(search)){
				_throwErrorFromXmlResponse(response);
			}

			// loop voices and add to return array, possibly filtering by supplied language
			for(i=1; i LTE ArrayLen(search); i=i+1){
				if(NOT StructKeyExists(arguments, 'languageFilter') OR Left(search[i].xmlValue, 2) EQ arguments.languageFilter){
					ArrayAppend( voices, search[i].xmlValue );
				}
			}
				
			return voices;
		</cfscript>
	</cffunction>

	<cffunction name="getFriends" access="public" returntype="array" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('LIST_FRIENDS') );
			var friends = XmlSearch( response, '/rsp/friend/@name' );
			var i = 0;
			
			for(i=1; i LTE ArrayLen(friends); i++){
				friends[i] = friends[i].xmlValue;
			}

			return friends;
		</cfscript>
	</cffunction>
	
	<cffunction name="getBlacklist" access="public" returntype="array" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_BLACKLIST') );
			var blacklist = XmlSearch( response, '/rsp/pseudo/@name' );
			var i = 0;
			
			for(i=1; i LTE ArrayLen(blacklist); i++){
				blacklist[i] = blacklist[i].xmlValue;
			}

			return blacklist;
		</cfscript>
	</cffunction>

	<cffunction name="getInboxMessages" access="public" returntype="array" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_INBOX_MESSAGES') );
			var messages = XmlSearch( response, '/rsp/msg' );
			var i = 0;
			
			for(i=1; i LTE ArrayLen(messages); i++){
				messages[i] = messages[i].xmlAttributes;
			}

			return messages;
		</cfscript>	
	</cffunction>
	
	<cffunction name="getTimezone" access="public" returntype="string" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_TIMEZONE') );

			try{
				return response.rsp.timezone.xmlText;
			} catch( any e ){
				_throwErrorFromXmlResponse( response );
			}
		</cfscript>	
	</cffunction>
	
	<cffunction name="getSignature" access="public" returntype="string" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_SIGNATURE') );

			try{
				return response.rsp.signature.xmlText;
			} catch( any e ){
				_throwErrorFromXmlResponse( response );
			}
		</cfscript>	
	</cffunction>
	
	<cffunction name="getName" access="public" returntype="string" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_NAME') );

			try{
				return response.rsp.rabbitname.xmlText;
			} catch( any e ){
				_throwErrorFromXmlResponse( response );
			}
		</cfscript>	
	</cffunction>

	<cffunction name="getVersion" access="public" returntype="string" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_VERSION') );

			try{
				return response.rsp.rabbitVersion.xmlText;
			} catch( any e ){
				_throwErrorFromXmlResponse( response );
			}
		</cfscript>	
	</cffunction>	
	
	<cffunction name="getLanguages" access="public" returntype="array" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_LANGUAGES') );
			var languages = XmlSearch( response, '/rsp/myLang/@lang' );
			var i = 0;
			
			for(i=1; i LTE ArrayLen(languages); i++){
				languages[i] = languages[i].xmlValue;
			}

			return languages;
		</cfscript>
	</cffunction>
	
	<cffunction name="isSleeping" access="public" returntype="boolean" output="false">
		<cfscript>
			var response = _serverCall( action=_getAction('GET_SLEEPING_STATUS') );

			try{
				return response.rsp.rabbitSleep.xmlText EQ 'YES';
			} catch( any e ){
				_throwErrorFromXmlResponse( response );
			}
		</cfscript>	
	</cffunction>
	
<!--- MAIN SERVER CALL METHOD (PRIVATE) --->
	<cffunction name="_serverCall" access="private" returntype="xml" output="false">
		<cfargument name="action" type="numeric" required="false" />
		<cfargument name="params" type="struct" required="false" default="#StructNew()#" />
		
		<cftry>
			<cfhttp url="#_getApiUrl()#" method="get">
				<cfhttpparam name="sn" type="url" value="#_getSerialNumber()#" />
				<cfhttpparam name="token" type="url" value="#_getToken()#" />
				
				<cfif StructKeyExists(arguments, 'action')>
					<cfhttpparam name="action" type="url" value="#arguments.action#" />
				</cfif>

				<cfloop collection="#arguments.params#" item="param">
					<cfhttpparam name="#param#" type="url" value="#arguments.params[param]#" />
				</cfloop>
			</cfhttp>
			
			<cfcatch>
				<cfset _throw("There was an error contacting the nabaztag server", "nabaztagApi.http", this.ERROR_HTTP) />
			</cfcatch>
		</cftry>
		
		<cfreturn _parseResponse( cfhttp.FileContent ) />
	</cffunction>

<!--- UTILITY --->
	<cffunction name="_isResponseAsExpected" access="private" returntype="boolean" output="false">
		<cfargument name="response" type="xml" required="true" hint="Parsed xml response from api call" />
		<cfargument name="expectedMessage" type="string" required="true" hint="Expected 'message' code from the server" />
		
		<cfscript>
			try {
				if( arguments.response.rsp.message.xmlText EQ arguments.expectedMessage ){
					return true;
				}
				_throwErrorFromXmlResponse( arguments.response );
			
			} catch( any e ){
				_throw();
			}
		</cfscript>
	</cffunction>

	<cffunction name="_throwErrorFromXmlResponse" access="private" returntype="void" output="false">
		<cfargument name="response" type="xml" required="true" hint="Parsed xml response from api call" />
		
		<cfscript>
			try {
				_throw( message=arguments.response.rsp.comment.xmlText, type=arguments.response.rsp.message.xmlText, code=this.ERROR_FROM_NABAZTAG );
			
			} catch( any e ){
				_throw();
			}
		</cfscript>
	</cffunction>

	<cffunction name="_throw" access="private" returntype="void" outpute="false">
		<cfargument name="message" type="string" required="false" default="The response from the nabaztag api could not be interpreted" />
		<cfargument name="type" type="string" required="false" default="nabaztagApi.badResponse" />
		<cfargument name="code" type="numeric" required="false" default="#this.ERROR_UNKNOWN#" />
			
		<cfthrow type="nabaztagApi.#arguments.type#" errorcode="#arguments.code#" message="#arguments.message#" />
	</cffunction>
	
	<cffunction name="_parseResponse" access="private" returntype="xml" output="false">
		<cfargument name="rawResponse" type="string" required="false" />
		
		<cfscript>
			var xml = "";

			// 1. attempt xml parse
			try{
				xml = XmlParse( arguments.rawResponse );
			} catch( any e ){
				_throw();
			}
			
			// 2. throw error if we know it's bad already
			if(IsDefined('xml.rsp.message.xmlText')){
				if(_isKnownError(xml.rsp.message.xmlText)){
					_throwErrorFromXmlResponse(xml);
				}
			}
			
			// 3. return the parsed xml
			return xml;
		</cfscript>
	</cffunction>
	
<!--- ACCESSORS (BLAH) --->
	<cffunction name="_setSerialNumber" access="private" returntype="string" output="false">
		<cfargument name="serialNumber" type="string" required="true" />
		<cfset _serialNumber = arguments.serialNumber />
	</cffunction>
	<cffunction name="_getSerialNumber" access="private" returntype="string" output="false">
		<cfreturn _serialNumber />
	</cffunction>
	
	<cffunction name="_setToken" access="private" returntype="string" output="false">
		<cfargument name="token" type="string" required="true" />
		<cfset _token = arguments.token />
	</cffunction>
	<cffunction name="_getToken" access="private" returntype="string" output="false">
		<cfreturn _token />
	</cffunction>
	
	<cffunction name="_setApiUrl" access="private" returntype="string" output="false">
		<cfargument name="apiUrl" type="string" required="true" />
		<cfset _apiUrl = arguments.apiUrl />
	</cffunction>
	<cffunction name="_getApiUrl" access="private" returntype="string" output="false">
		<cfreturn _apiUrl />
	</cffunction>

	<cffunction name="_setDefaultVoice" access="private" returntype="string" output="false">
		<cfargument name="defaultVoice" type="string" required="true" />
		<cfset _defaultVoice = arguments.defaultVoice />
	</cffunction>
	<cffunction name="_getDefaultVoice" access="private" returntype="string" output="false">
		<cfreturn _defaultVoice />
	</cffunction>

	<cffunction name="_setupActions" access="private" returntype="void" output="false">
		<cfscript>
			// odd way of doing things, actions in the Nabaztag API are all defined by a number
			// this is an attempt to make that readable
			variables._actions = StructNew();
			
			_actions.TTS_PREVIEW = 1;
			_actions.LIST_FRIENDS = 2;
			_actions.GET_INBOX_MESSAGES = 3;
			_actions.GET_TIMEZONE = 4;
			_actions.GET_SIGNATURE = 5;
			_actions.GET_BLACKLIST = 6;
			_actions.GET_SLEEPING_STATUS = 7;
			_actions.GET_VERSION = 8;
			_actions.GET_SUPPORTED_VOICES = 9;
			_actions.GET_NAME = 10;
			_actions.GET_LANGUAGES = 11;
			_actions.MESSAGE_PREVIEW = 12;
			_actions.SEND_TO_SLEEP = 13;
			_actions.WAKE_UP = 14;
		</cfscript>
	</cffunction>	
	<cffunction name="_getAction" access="private" returntype="numeric" output="false">
		<cfargument name="action" type="string" required="true" />
		
		<cfif StructKeyExists(_actions, arguments.action)>
			<cfreturn _actions[arguments.action] />
		</cfif>
		
		<cfreturn 0 />
	</cffunction>
	
	<cffunction name="_setupKnownErrors" access="private" returntype="void" output="false">
		<cfset _knownErrors = "ABUSESENDING,NOGOODTOKENORSERIAL,MESSAGENOTSENT,NABCASTNOTSENT,TTSNOTSENT,CHORNOTSENT,EARPOSITIONNOTSENT,WEBRADIONOTSENT,NOCORRECTPARAMETERS,NOTV2RABBIT" />
	</cffunction>
	<cffunction name="_isKnownError" access="private" returntype="boolean" output="false">
		<cfargument name="message" type="string" required="true" />
		
		<cfreturn ListFindNoCase(_knownErrors, arguments.message) />
	</cffunction>
</cfcomponent>