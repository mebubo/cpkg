let concatMapSep = https://raw.githubusercontent.com/dhall-lang/dhall-lang/master/Prelude/Text/concatMapSep
in

let showVersion =
  λ(x : List Natural) → concatMapSep "." Natural Natural/show x
in

let mkTarget =
  λ(x : Optional Text) →
    Optional/fold Text x Text (λ(tgt : Text) → " --target=${tgt}") ""
in

let defaultConfigure =
  λ(cfg : { installDir : Text, targetTriple : Optional Text, includeDirs : List Text}) →
    [ "./configure --prefix=" ++ cfg.installDir ++ mkTarget cfg.targetTriple ]
in

let defaultBuild =
  λ(cpus : Natural) →
    [ "make -j" ++ Natural/show cpus ]
in

let defaultPackage =
  { configureCommand = defaultConfigure
  , executableFiles  = [ "configure" ]
  , buildCommand     = defaultBuild
  , installCommand   = [ "make install" ]
  }
in

let makeGnuPackage =
  λ(pkg : { name : Text, version : List Natural}) →
    defaultPackage ⫽
      { pkgName = pkg.name
      , pkgVersion = pkg.version
      , pkgUrl = "https://mirrors.ocf.berkeley.edu/gnu/lib${pkg.name}/lib${pkg.name}-${showVersion pkg.version}.tar.xz"
      , pkgSubdir = "lib${pkg.name}-${showVersion pkg.version}"
      }
in

{ showVersion    = showVersion
, makeGnuPackage = makeGnuPackage
, defaultPackage = defaultPackage
}
