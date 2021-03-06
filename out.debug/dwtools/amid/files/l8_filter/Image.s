( function _Image_s_() {

'use strict';

// if( typeof module !== 'undefined' )
// {
//
//   let _global = _global_;
//   let _ = _global_.wTools;
//
//   // require( '../IncludeArchive.s' );
//
// }

//

let _global = _global_;
let _ = _global_.wTools;
let Abstract = _.FileProvider.Abstract;
// let Partial = _.FileProvider.Partial;
// let Default = _.FileProvider.Default;
let Parent = Abstract;
let Self = function wFileFilterImage( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'Image';

// --
//
// --

function init( o )
{
  let self = this;

  _.assert( arguments.length <= 1 );
  _.instanceInit( self )
  Object.preventExtensions( self );

  if( o )
  self.copy( o );

  let accessors =
  {
    get : function( self, k, proxy )
    {
      let result;
      if( self[ k ] !== undefined )
      result = self[ k ];
      else
      result = self.originalFileProvider[ k ];
      if( self._routineDrivingAndChanging( result ) )
      return self._routineFunctor( result, k );
      return result;
    },
    set : function( self, k, val, proxy )
    {
      if( self[ k ] !== undefined )
      self[ k ] = val;
      else if( self.originalFileProvider[ k ] !== undefined )
      self.originalFileProvider[ k ] = val;
      else
      self[ k ] = val;
      return true;
    },
  };

  let proxy = new Proxy( self, accessors );

  self.proxy = proxy;
  self.imageFilter = self;
  if( !self.originalFileProvider )
  self.originalFileProvider = _.fileProvider;

  self.realFileProvider = self.originalFileProvider;
  while( self.realFileProvider.originalFileProvider )
  self.realFileProvider = self.realFileProvider.originalFileProvider;

  _.assert( self.originalFileProvider instanceof _.FileProvider.Partial );
  _.assert( self.realFileProvider instanceof _.FileProvider.Partial );

  return proxy;
}

//

function _routineDrivingAndChanging( routine )
{

  _.assert( arguments.length === 1 );

  if( !_.routineIs( routine ) )
  return false;

  if( !routine.having )
  return false;

  if( !routine.having.reading && !routine.having.writing )
  return false;

  if( !routine.having.driving )
  return false;

  _.assert( _.objectIs( routine.operates ), () => 'Method ' + routine.name + ' does not have map {-operates-}' );

  if( _.mapKeys( routine.operates ).length === 0 )
  return false;

  return true;
}

//

function _routineFunctor( routine, routineName )
{
  let self = this;

  _.assert( arguments.length === 2 );
  _.assert( _.routineIs( routine ) );
  _.assert( !!routine.having );
  _.assert( !!routine.having.reading || !!routine.having.writing );
  _.assert( !!routine.having.driving );
  _.assert( !!routine.operates );
  _.assert( _.mapKeys( routine.operates ).length > 0 );
  _.assert( _.strDefined( routineName ) );
  _.assert( routine.name === routineName );

  if( self.routines[ routineName ] )
  return self.routines[ routineName ];

  let pre = routine.pre;
  let body = routine.body || routine;
  let op = Object.create( null );
  op.routine = routine;
  op.routineName = routineName;
  op.reads = [];
  op.writes = [];
  op.image = self.proxy;
  op.originalCall = function originalCall()
  {
    let op2 = this;
    _.assert( arguments.length === 0 );
    _.assert( _.arrayLike( op2.args ) );
    op2.result = op2.originalBody.apply( op2.image, op2.args );
  }

  for( let k in routine.operates )
  {
    let arg = routine.operates[ k ];
    if( arg.pathToRead )
    op.reads.push( k );
    if( arg.pathToWrite )
    op.writes.push( k );
  }

  let r =
  {
    [ routineName ] : function()
    {
      let op2 = _.mapExtend( null, op );
      op2.originalFileProvider = this.originalFileProvider;
      op2.originalBody = body;
      op2.args = _.unrollFrom( arguments );
      op2.result = undefined;

      if( pre )
      {
        debugger;
        _.assert( 0, 'not tested' );
        op2.args = pre.call( this.originalFileProvider, resultRoutine, op2.args );
        if( !_.unrollIs( op2.args ) )
        op2.args = _.unrollFrom([ op2.args ]);
      }

      if( this.onCallBegin )
      {
        let r = this.imageFilter.onCallBegin( op2 );
        _.assert( r === undefined );
      }

      if( !_.unrollIs( op2.args ) )
      op2.args = _.unrollFrom([ op2.args ]);

      _.assert( !_.argumentsArrayIs( op2.args ), 'Does not expect arguments array' );
      let r = this.imageFilter.onCall( op2 );
      _.assert( r === undefined );

      if( this.onCallEnd )
      {
        let r = this.imageFilter.onCallEnd( op2 );
        _.assert( r === undefined );
      }

      return op2.result;
    }
  }

  let resultRoutine = self.routines[ routineName ] = r[ routineName ];

  _.routineExtend( resultRoutine, routine );

  return resultRoutine;
}

//

function onCall( op )
{
  _.assert( arguments.length === 1 );
  op.result = op.originalBody.apply( op.originalFileProvider, op.args );
}

// --
// relationship
// --

let Composes =
{
}

let Aggregates =
{
  onCallBegin : null,
  onCall : onCall,
  onCallEnd : null,
}

let Associates =
{
  originalFileProvider : null,
  realFileProvider : null,
  // original : null,
  // fileProvider : null,
}

let Restricts =
{
  routines : _.define.own({}),
  proxy : null,
  imageFilter : null,
}

let Events =
{
}

let Frobids =
{
  original : 'original',
  fileProvider : 'fileProvider',
}

// --
// declare
// --

let Extend =
{

  init,

  _routineDrivingAndChanging,
  _routineFunctor,

  //

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Events,
  Frobids,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.Copyable.mixin( Self );
// _.EventHandler.mixin( Self );

//

_.FileFilter = _.FileFilter || Object.create( null );
_.FileFilter[ Self.shortName ] = Self;

// --
// export
// --

// if( typeof module !== 'undefined' )
// if( _global_.WTOOLS_PRIVATE )
// { /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
