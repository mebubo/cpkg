module Package.C.Build ( buildCPkg
                       ) where

import           Data.Foldable    (traverse_)
import           Package.C.Error
import           Package.C.Fetch
import           Package.C.Type
import           System.Directory (createDirectoryIfMissing, getAppUserDataDirectory)
import           System.Exit      (ExitCode (ExitSuccess), exitWith)
import           System.FilePath  ((</>))
import           System.IO.Temp   (withSystemTempDirectory)
import           System.Process   (CreateProcess (cwd, std_in), StdStream (NoStream), createProcess, proc, waitForProcess)

handleExit :: ExitCode -> IO ()
handleExit ExitSuccess = mempty
handleExit x           = exitWith x

cPkgToDir :: CPkg -> IO FilePath
cPkgToDir cpkg = getAppUserDataDirectory (".cpkg" </> _pkgName cpkg)

stepToProc :: String -- ^ Step
           -> FilePath -- ^ Working directory
           -> IO CreateProcess
stepToProc s fp = case words s of
    x:xs -> pure $ (proc x xs) { cwd = Just fp, std_in = NoStream }
    _    -> badCommand

waitProcess :: CreateProcess -> IO ()
waitProcess proc' = do
    (_, _, _, r) <- createProcess proc'
    handleExit =<< waitForProcess r

processSteps :: Traversable t => FilePath -> t String -> IO ()
processSteps pkgDir steps = traverse_ waitProcess =<< traverse (stepToProc pkgDir) steps

configureInDir :: CPkg -> FilePath -> FilePath -> IO ()
configureInDir cpkg pkgDir p =

    let cfg = ConfigureVars pkgDir []
        steps = _configureCommand cpkg cfg
    in
        processSteps p steps

buildInDir :: CPkg -> FilePath -> IO ()
buildInDir cpkg p = processSteps p (_buildCommand cpkg)

installInDir :: CPkg -> FilePath -> IO ()
installInDir cpkg p = processSteps p (_installCommand cpkg)

fetchCPkg :: CPkg
          -> FilePath -- ^ Directory for intermediate build files
          -> IO ()
fetchCPkg cpkg = fetchUrl (_pkgUrl cpkg) (_pkgName cpkg)

-- TODO: more complicated solver, garbage collector, and all that.
-- Basically nix-style builds for C libraries
--
-- TODO: This should take a verbosity
-- TODO: play nicely with cross-compilation (lol)
buildCPkg :: CPkg -> IO ()
buildCPkg cpkg = do

    pkgDir <- cPkgToDir cpkg

    createDirectoryIfMissing True pkgDir

    withSystemTempDirectory "cpkg" $ \p -> do

        putStrLn ("unpacking to " ++ p)

        fetchCPkg cpkg p

        configureInDir cpkg pkgDir p

        buildInDir cpkg p

        installInDir cpkg p