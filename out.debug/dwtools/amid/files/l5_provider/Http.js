( function _Http_js_() {

'use strict';

if( typeof module !== 'undefined' )
{
  let _ = require( '../../../Tools.s' );
  if( !_.FileProvider )
  require( '../UseMid.s' );
}

//

let _global = _global_;
let _ = _global_.wTools;
let Parent = _.FileProvider.Partial;
let Self = function wFileProviderHttp( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'Url';

_.assert( !_.FileProvider.Url );

// --
// inter
// --

function init( o )
{
  let self = this;
  Parent.prototype.init.call( self,o );
}

//

function pathCurrentAct()
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  if( arguments.length === 1 && arguments[ 0 ] )
  {
    let path = arguments[ 0 ];
    _.assert( self.path.is( path ) );
    self._currentPath = path;
  }

  let result = self._currentPath;

  return result;
}

//

function statReadAct( o )
{
  let self = this;
  let result = new _.FileStat();
  let con;

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assertRoutineOptions( statReadAct,arguments );

  /* */

  function errorGive( err )
  {
    result = null;
    if( o.throwing )
    {
      err = _.err( err );
      if( con )
      con.error( err );
      else
      throw err
    }
    return null;
  }

  /* */

  function fileSizeGet()
  {

    debugger;
    let request = new XMLHttpRequest();
    request.open( 'HEAD', o.filePath, !o.sync );
    request.onreadystatechange = function( e )
    {

      if( this.status !== 200 )
      {
        return errorGive( '#' + this.status + ' : ' + this.statusText );
      }

      if( this.readyState == this.DONE )
      {
        let size = parseInt( request.getResponseHeader( 'Content-Length' ) );
        result.size = size;
        if( con )
        con.take( result );
      }
    }
    request.send();
  }

  /* */

  function getFileStat()
  {
    result.isFile = function() { return true; };
    result.isDir = function() { return false; };
    try
    {
      fileSizeGet();
    }
    catch( err )
    {
      debugger;
      return errorGive( err );
    }
    return result;
  }

  /* */

  if( o.sync )
  {
    return getFileStat( o.filePath );
  }
  else
  {
    con = new _.Consequence();
    getFileStat( o.filePath );
    return con;
  }

}

statReadAct.defaults = Object.create( Parent.prototype.statReadAct.defaults );
statReadAct.having = Object.create( Parent.prototype.statReadAct.having );

//

function fileReadAct( o )
{
  let self = this;
  let con = _.Consequence();
  let Reqeust,request,total,result;

  // if( _.strIs( o ) )
  // o = { filePath : o };

  _.assertRoutineOptions( fileReadAct,arguments );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( o.filePath ),'fileReadAct :','Expects {-o.filePath-}' );
  _.assert( _.strIs( o.encoding ),'fileReadAct :','Expects {-o.encoding-}' );
  // _.assert( !o.sync,'fileReadAct :','synchronous version is not implemented' );

  o.encoding = o.encoding.toLowerCase();
  let encoder = fileReadAct.encoders[ o.encoding ];

  // advanced

  if( !o.advanced )
  o.advanced = {};

  _.mapComplement( o.advanced,fileReadAct.advanced );
  _.assertMapHasOnly( o.advanced,fileReadAct.advanced );

  o.advanced.method = o.advanced.method.toUpperCase();

  // http request

  if( typeof XMLHttpRequest !== 'undefined' )
  Reqeust = XMLHttpRequest;
  else if( typeof ActiveXObject !== 'undefined' )
  Reqeust = new ActiveXObject( 'Microsoft.XMLHTTP' );
  else
  {
    throw _.err( 'not implemented' );
  }

  /* handler */

  function getData( response )
  {
    if( request.responseType === 'text' )
    return response.responseText || response.response;
    if( request.responseType === 'document' )
    return response.responseXML || response.response;
    return response.response;
  }

  /* begin */

  function handleBegin()
  {

    // if( o.encoding !== 'utf8' )
    // debugger;

    if( encoder && encoder.onBegin )
    _.sure( encoder.onBegin.call( self, { operation : o, encoder : encoder }) === undefined );

    if( !o.sync )
    if( encoder && encoder.responseType )
    request.responseType = encoder.responseType;

  }

  /* end */

  function handleEnd( e )
  {

    if( o.ended )
    return;

    try
    {

      result = getData( request );

      let context = { data : result, operation : o, encoder : encoder };
      if( encoder && encoder.onEnd )
      _.sure( encoder.onEnd.call( self, context ) === undefined );
      result = context.data

      o.ended = 1;

      con.take( result );
    }
    catch( err )
    {
      handleError( err );
    }

  }

  /* progress */

  function handleProgress( e )
  {
    console.debug( 'REMINDER : implement handleProgress' );
    // not implemented well
    if( e.lengthComputable )
    if( o.onProgress )
    _.Consequence.take( o.onProgress,
    {
      progress : e.loaded / e.total,
      options : o,
    });
  }

  /* error */

  function handleError( err )
  {

    o.ended = 1;

    if( encoder && encoder.onError )
    try
    {
      err = _._err
      ({
        args : [ stack,'\nfileReadAct( ',o.filePath,' )\n',err ],
        usingSourceCode : 0,
        level : 0,
      });
      err = encoder.onError.call( self,{ error : err, operation : o, encoder : encoder })
    }
    catch( err2 )
    {
      console.error( err2 );
      console.error( err.toString() + '\n' + err.stack );
    }

    con.error( err );
  }

  /* error event */

  function handleErrorEvent( e )
  {
    let err = _.err( 'Network error',e );
    return handleError( err );
  }

  /* state */

  function handleState( e )
  {

    if( o.ended )
    return;

    if( this.readyState === 2 )
    {

    }
    else if( this.readyState === 3 )
    {

      let data = getData( this );
      if( !data ) return;
      if( !total ) total = this.getResponseHeader( 'Content-Length' );
      total = Number( total ) || 1;
      if( isNaN( total ) ) return;
      handleProgress( data.length / total,o );

    }
    else if( this.readyState === 4 )
    {

      if( o.ended )
      return;

      /*if( this.status === 200 || this.status === 0 )*/
      if( this.status === 200 )
      {

        handleEnd( e );

      }
      else if( this.status === 0 )
      {
      }
      else
      {

        handleError( '#' + this.status );

      }

    }

  }

  /* set */

  request = o.request = new Reqeust();

  if( !o.sync )
  request.responseType = 'text';

  request.addEventListener( 'progress', handleProgress );
  request.addEventListener( 'load', handleEnd );
  request.addEventListener( 'error', handleErrorEvent );
  request.addEventListener( 'timeout', handleErrorEvent );
  request.addEventListener( 'readystatechange', handleState );
  request.open( o.advanced.method, o.filePath, !o.sync, o.advanced.user, o.advanced.password );
  /*request.setRequestHeader( 'Content-type','application/octet-stream' );*/

  handleBegin();

  try
  {
    if( o.advanced && o.advanced.send !== null )
    request.send( o.advanced.send );
    else
    request.send();
  }
  catch( err )
  {
    handleError( err );
  }

  if( o.sync )
  return result;
  else
  return con;
}

fileReadAct.defaults = Object.create( Parent.prototype.fileReadAct.defaults );
fileReadAct.having = Object.create( Parent.prototype.fileReadAct.having );

fileReadAct.advanced =
{

  send : null,
  method : 'GET',
  user : null,
  password : null,

}

// --
// encoders
// --

var encoders = {};

encoders[ 'utf8' ] =
{

  responseType : 'text',
  onBegin : function( e )
  {
    // e.operation.encoding = 'text';
  },

}

encoders[ 'buffer.raw' ] =
{

  responseType : 'arraybuffer',
  onBegin : function( e )
  {
    // e.operation.encoding = 'arraybuffer';
  },

}

//

encoders[ 'buffer.bytes' ] =
{

  responseType : 'arraybuffer',

  onBegin : function( e )
  {
    _.assert( e.operation.encoding === 'buffer.bytes' );
  },

  onEnd : function( e )
  {
    e.data = _.bufferBytesFrom( e.data );
  },

}

//

encoders[ 'blob' ] =
{

  responseType : 'blob',
  onBegin : function( e )
  {
    debugger;
    throw _.err( 'not tested' );
    e.operation.encoding = 'blob';
  },

}

encoders[ 'document' ] =
{

  responseType : 'document',
  onBegin : function( e )
  {
    debugger;
    throw _.err( 'not tested' );
    e.operation.encoding = 'document';
  },

}

fileReadAct.encoders = encoders;

// --
// relationship
// --

let Composes =
{

  safe : 0,
  stating : 0,
  protocols : _.define.own([ 'http' ]),

  resolvingSoftLink : 0,
  resolvingTextLink : 0,

}

let Aggregates =
{
}

let Associates =
{
}

let Restricts =
{
  _currentPath : '/',
}

let Statics =
{
  Path : _.weburi.CloneExtending({ fileProvider : Self }),
}

// --
// declare
// --

let Proto =
{

  init : init,

  // read

  pathCurrentAct : pathCurrentAct,
  statReadAct : statReadAct,
  fileReadAct : fileReadAct,

  //

  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

if( _.FileProvider.Find )
_.FileProvider.Find.mixin( Self );
if( _.FileProvider.Secondary )
_.FileProvider.Secondary.mixin( Self );

//

if( Config.platform === 'browser' )
if( !_.FileProvider.Default )
{
  _.FileProvider.Default = Self;
  if( !_.fileProvider )
  _.FileProvider.Default.MakeDefault();
}

// --
// export
// --

_.FileProvider[ Self.shortName ] = Self;

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
{ /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
