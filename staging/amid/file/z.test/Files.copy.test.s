( function _Files_copy_test_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  try
  {
    require( '../../../abase/wTools.s' );
  }
  catch( err )
  {
    require( 'wTools' );
  }

  var _ = wTools;

  require( '../FileMid.s' );

  _.include( 'wTesting' );

  // var rootDir = _.pathResolve( __dirname + '/../../../../tmp.tmp'  );

}

var _ = wTools;
var Parent = wTools.Testing;

//

function filesCopy( test )
{

  /* Map of test cases
      * level : 0, 1, 2
    (
      presence of file : missing, present
      +
      if present
      (
        * kind of file : empty directory, no empty directory, terminal
        * linkage of file : ordinary, soft
      )
    )
    ^ where file : src, dst
    3 * ( 1 + 2 * 3  ) ^ 2 = 3 * 7 ^ 2 = 3 * 49 = 147
  */

  //

  var testDir = _.pathResolve( __dirname, '../../../../tmp.tmp/filesCopy' );
  var pathDst, pathSrc;

  var fileRead = ( path ) => _.fileProvider.fileRead( path );
  var dirRead = ( path ) => _.fileProvider.directoryRead( path );
  var dirTestClean = () => _.fileProvider.fileDelete( testDir );
  var fileMake = ( path ) => _.fileProvider.fileWrite( path, path );
  var fileStats = ( path ) => _.fileProvider.fileStat( path );

  pathDst = _.pathJoin( testDir, 'dst' );
  pathSrc = _.pathJoin( testDir, 'src' );

  var filePathSrc = _.pathJoin( pathSrc, 'file.src' );
  var filePathDst = _.pathJoin( pathDst, 'file.dst' );
  var filePathSoftSrc = _.pathJoin( pathSrc, 'file.soft.src' );
  var filePathSoftDst = _.pathJoin( pathDst, 'file.soft.dst' );

  //

  var fixedDefaults =
  {
    allowDelete : 0,
    allowWrite : 0,
    allowRewrite : 0,
    allowRewriteFileByDir : 0,
  }

  var defaultCases =
  [
    {
      o : { dst : pathDst, src : pathSrc },
      shouldThrowError : true,
    },
    {
      o : { dst : pathDst, src : filePathSoftSrc },
      pre : function ()
      {
        _.fileProvider.fileWrite( filePathSrc, 'src' );
        _.fileProvider.linkSoft( filePathSoftSrc, filePathSrc );
      },
      shouldThrowError : true,
    },

  ]

  //

  test.description = 'default options';

  for( var i = 0 ; i < defaultCases.length ; i++ )
  {
    var _case = defaultCases[ i ];
    _.mapSupplement( _case.o, fixedDefaults );

    dirTestClean();

    if( _case.pre )
    _case.pre();

    var dstBefore = _.fileProvider.directoryRead( _case.o.dst );
    var srcBefore = _.fileProvider.directoryRead( _case.o.src );

    if( _case.shouldThrowError )
    test.shouldThrowError( () => _.fileProvider.filesCopy( _case.o ) );
    else
    {
      var got = _.fileProvider.filesCopy( _case.o );
      test.shouldBe( _.arrayLike( got ) );
      test.identical( got.length, 1 );
      test.shouldBe( _.objectIs( got[ 0 ] ) );
    }

    var dstAfter = _.fileProvider.directoryRead( _case.o.dst );
    var srcAfter = _.fileProvider.directoryRead( _case.o.src );

    test.identical( dstBefore, dstAfter );
    test.identical( srcBefore, srcAfter );

  }

  //

  var fixedOptions =
  {
    allowDelete : 1,
    allowWrite : 1,
    allowRewrite : 1,
    allowRewriteFileByDir : 1,
    recursive : 1
  }

  var o =
  {
    dst : null,
    src : null
  };

  _.mapSupplement( o, fixedOptions );

  var typeOfFiles = [ 'terminal', 'empty directory', 'directory' ];
  var linkage = [ 'ordinary', 'soft' ];
  var levels = 1;

  function prepereFile( path, type, link, level )
  {
    if( level > 0 && type != 'terminal' )
    {
      for( var l = 1 ; l <= level; l++ )
      path = _.pathJoin( path, 'level' + l );
      // console.log( path );
    }

    var _path = path;

    if( link === 'soft' )
    {
      path += '_';
    }

    if( type === 'terminal' || type === 'directory' )
    {
      if( type === 'directory' )
      fileMake( _.pathJoin( path, 'file' ) );
      else
      fileMake( path );
    }

    if( type === 'empty directory' )
    _.fileProvider.directoryMake( path );

    if( link === 'soft' )
    {
      _.fileProvider.linkSoft( _path, path );
    }
  }

  /* src is present -> dst present/missing */

  for( var k = 0 ; k < linkage.length ; k++ )
  {
    var linkSrc = linkage[ k ];

    for( var i = 0; i < typeOfFiles.length; i++ )
    {
      for( var l = 0 ; l < levels ; l++ )
      {
        dirTestClean();

        var kindOfSrc = typeOfFiles[ i ];

        var info =
        {
          level : l,
          presenceOfSrc : 'present',
          kindOfSrc : kindOfSrc,
          linkageOfSrc : linkSrc,
          direction : 'src -> dst',
        };

        o.src = pathSrc;

        if( kindOfSrc === 'terminal' )
        {
          o.src = _.pathJoin( pathSrc, 'file.src' );
          prepereFile( o.src, kindOfSrc, linkSrc, l );
        }

        if( kindOfSrc === 'directory' || kindOfSrc === 'empty directory' )
        {
          o.src = pathSrc;
          prepereFile( o.src, kindOfSrc, linkSrc, l );
        }

        /* dst is present */

        for( var x = 0; x < linkage.length; x++ )
        {
          var linkDst = linkage[ x ];
          for( var j = 0; j < typeOfFiles.length; j++ )
          {
            _.fileProvider.fileDelete( pathDst );

            var kindOfDst = typeOfFiles[ j ];

            info.presenceOfDst = 'present';
            info.kindOfDst = kindOfDst;
            info.linkageOfDst = linkDst;
            info.options = o;

            logger.log( _.toStr( info, { levels : 2 } ) );

            var description =
            'level : ' + l
            + ' linkage : ' + linkSrc + ' ' + kindOfSrc
            + ' -> '
            + 'linkage : ' + linkDst + ' ' + kindOfDst;
            test.description = description;

            if( kindOfDst === 'terminal' )
            {
              o.dst = _.pathJoin( pathDst, 'file.dst' );
              prepereFile( o.dst, kindOfDst, linkDst );
            }
            if( kindOfDst === 'directory' || kindOfDst === 'empty directory' )
            {
              o.dst = pathDst;
              prepereFile( o.dst, kindOfDst, linkDst );
            }

            var src = fileStats( o.src );
            var srcFiles = dirRead( o.src );
            var dstFiles = dirRead( o.dst );

            if( linkSrc === 'soft'  )
            {
              if( linkDst === 'ordinary' )
              {
                test.shouldThrowError( () => _.fileProvider.filesCopy( o ) )
                // console.log( _.toStr( got, { levels : 3 } ) );
                continue;
              }
            }
            else
            var got = _.fileProvider.filesCopy( o );

            test.description = description + ', check if src not changed ';
            /* check if nothing removed from src */
            test.identical( dirRead( o.src ), srcFiles );

            if( kindOfSrc === 'empty directory' )
            {
              /* check if nothing changed in dst */
              test.identical( dirRead( o.dst ), dstFiles );
              continue;
            }

            test.description = description + ', check if files from src was copied to dst ';

            if( kindOfSrc !== 'terminal' &&  kindOfSrc !== 'empty directory' )
            test.identical( dirRead( o.dst ), srcFiles );

            var dst = fileStats( o.dst );

            if( !_.objectIs( dst ) )
            {
              _.errLog
              (
                'action : ' + got[ 0 ].action
                + ' ' + _.strShort( got[ 0 ].src.real )
                + ' -> ' + _.strShort( got[ 0 ].dst.real )
              );
              test.identical( 0, 1 );
              continue;
            }

            test.identical( src.size, dst.size );
            test.identical( src.isDirectory(), src.isDirectory() );
          }
        }

        /* dst is missing */

        info.presenceOfDst = 'missing';
        info.kindOfDst = null;
        info.linkageOfDst = null;
        info.options = o;

        logger.log( _.toStr( info, { levels : 2 } ) );

        test.description = 'level : ' + l + ' linkage : ' + linkSrc + ' ' + kindOfSrc + ' dst is missing';

        _.fileProvider.fileDelete( pathDst );

        o.dst = pathDst;

        if( linkSrc === 'soft' )
        {
          test.shouldThrowError( () => _.fileProvider.filesCopy( o ) );
          continue;
        }

        var got = _.fileProvider.filesCopy( o );

        var dst = fileStats( o.dst );
        var src = fileStats( o.src );
        test.identical( _.objectIs( src ), true );
        test.identical( _.objectIs( dst ), true );
        if( !_.objectIs( dst ) )
        {
          test.identical( 0, 1 );
          _.errLog( 'action : ' + got[ 0 ].action );
          continue;
        }
        test.identical( dst.size, src.size );
        test.identical( dst.isDirectory(), src.isDirectory() );

        test.identical( dirRead( o.dst ), dirRead( o.src ) );
      }
    }
  }

}

// --
// proto
// --

var Self =
{

  name : 'FilesAdvancedTest',
  // verbosity : 0,

  tests :
  {
    filesCopy : filesCopy,
  },

}

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
_.Testing.test( Self.name );

})();