( function _FileProvider_HardDrive_test_ss_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  require( './aFileProvider.test.s' );

}

//

var _ = wTools;
var Parent = wTests[ 'FileProvider' ];

_.assert( Parent );

//

function makePath( filePath )
{
  filePath =  _.pathJoin( this.testRootDirectory,  filePath );
  return this.provider.pathNativize( filePath );
}

//

function pathsAreLinked( paths )
{
  var linked = true;
  var statsFirst = this.provider.fileStat( paths[ 0 ] );
  for( var i = 1; i < paths.length; i++ )
  {
    var statCurrent = this.provider.fileStat( paths[ i ] );
    linked &= _.statsAreLinked( statsFirst, statCurrent );
    if( !linked )
    break;
  }

  return linked;
}

//

function linkGroups( paths, groups )
{
  groups.forEach( ( g ) =>
  {
    if( g.length >= 2 )
    {
      var filePathes = g.map( ( i ) => paths[ i ] );
      this.provider.linkHard({ filePathes : filePathes });
    }
  })
}

//

function makeFiles( names, dirPath, data )
{
  var self = this;

  if( !_.arrayIs( data ) )
  data = _.arrayFillTimes( [], names.length, data );

  _.assert( data.length === names.length );

  var paths = names.map( ( p )  => self.makePath( _.pathJoin( dirPath, p ) ) );
  paths.forEach( ( p, i )  =>
  {
    if( self.provider.fileStat( p ) )
    self.provider.fileTouch({ filePath : p, purging : 1 });

    self.provider.fileWrite( p, data[ i ] )
  });

  return paths;
}

//

function testDirMake( test )
{
  var self = this;
  self.testRootDirectory = _.dirTempMake( _.pathJoin( __dirname, '../..'  ) );
}

//

function testDirClean()
{
  var self = this;
  self.provider.fileDelete( self.testRootDirectory );
}

// --
// proto
// --

var Proto =
{

  name : 'FileProvider.HardDrive',
  abstract : 0,
  silencing : 1,

  onSuiteBegin : testDirMake,
  onSuiteEnd : testDirClean,

  context :
  {
    provider : _.FileProvider.HardDrive(),
    makePath : makePath,
    makeFiles : makeFiles,
    pathsAreLinked : pathsAreLinked,
    linkGroups : linkGroups,
    testDirMake : testDirMake,
    testRootDirectory : null,
    testFile : null,
    // testRootDirectory : __dirname + '/../../../../tmp.tmp/hard-drive',
    // testFile : __dirname + '/../../../../tmp.tmp/hard-drive/test.txt',
  },

  tests :
  {
    // fileRenameSync : null,
  },

}

//

// var Self = new wTestSuite( Parent ).extendBy( Proto );
var Self = new wTestSuite( Proto ).inherit( Parent );
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );

} )( );