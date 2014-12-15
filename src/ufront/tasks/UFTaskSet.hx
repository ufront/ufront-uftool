package ufront.tasks;

import mcli.CommandLine;
import minject.Injector;
import sys.io.*;
import sys.FileSystem;
import ufront.log.FileLogger;
import ufront.log.Message;
import ufront.log.MessageList;
import ufront.api.UFApi;
import haxe.PosInfos;
using ufront.core.InjectionTools;
using haxe.io.Path;

class UFTaskSet extends CommandLine {

	/**
		The injector for this task set.

		Set during the constructor, and injection into this object is performed immediately.
	**/
	@:skip public var injector(default,null):Injector;
	
	/**
		The messages list.  This must be injected for `ufTrace`, `ufLog`, `ufWarn` and `ufError` to function correctly.
		
		You can call `useCLILogging()` to set up a message list appropriate for CLI usage.
	**/
	@:skip @inject public var messages:MessageList;

	/**
		Set up the TaskSet.

		This will perform dependency injection
	**/
	public function new( ?injector:Injector ) {
		super();
		this.injector = (injector!=null) ? injector : new Injector();
		inject( Injector, this.injector );
	}

	/**
		Shortcut to map a class into `injector`.

		See `ufront.core.InjectionTools.inject()` for details on how injection is performed.

		This method is chainable.
	**/
	@:skip
	public function inject<T>( cl:Class<T>, ?val:T, ?cl2:Class<T>, ?singleton:Bool=false, ?named:String ):UFTaskSet {
		injector.inject( cl, val, cl2, singleton, named );
		return this;
	}

	/**
		Set up the logging to direct all traces, logs, warnings and error messages to the command line.

		Optionally you can also write to a logFile (the path should be specified relative to the content directory).
	**/
	@:skip
	public function useCLILogging( ?logFile:String ):UFTaskSet {
		var file:FileOutput = null;
		if ( logFile!=null ) {
			var contentDir:String = injector.getInstance( String, "contentDirectory" );
			var logFilePath = contentDir.addTrailingSlash()+logFile;
			var logFileDirectory = logFilePath.directory();
			if ( FileSystem.exists(logFileDirectory)==false )
				FileSystem.createDirectory( logFileDirectory );
			file = File.append( logFilePath );
			var line = '${Date.now()} [UFTask Runner] ${Sys.args()}';
			file.writeString( '$line\n' );
		}
		function onMessage( msg:Message ) {
			var line = FileLogger.format( msg );
			Sys.println( line );
			if ( file!=null ) {
				file.writeString( '\t$line\n' );
			}
		}
		haxe.Log.trace = function(msg:Dynamic,?pos:PosInfos) onMessage({ msg: msg, pos: pos, type:Trace });
		var messageList = new MessageList(onMessage);
		injector.mapValue( MessageList, messageList );
		return this;
	}

	/**
		Execute the current task set, given a set of parameters passed in from the command line.
		
		Example usage:

		```haxe
		new Tasks().execute( Sys.args() );
		```
	**/
	@:skip
	public function execute( args:Array<String> ) {
		injector.injectInto( this );
		new mcli.Dispatch( args ).dispatch( this );
	}

	/**
		A shortcut to `HttpContext.ufTrace`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufTrace( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Trace });

	/**
		A shortcut to `HttpContext.ufLog`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufLog( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Log });

	/**
		A shortcut to `HttpContext.ufWarn`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufWarn( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Warning });

	/**
		A shortcut to `HttpContext.ufError`

		A `messages` array must be injected for these to function correctly.  Use `ufront.tasks.UFTaskSet.run()` to inject this correctly.
	**/
	@:noCompletion inline function ufError( msg:Dynamic, ?pos:PosInfos ) messages.push({ msg: msg, pos: pos, type:Error });
}