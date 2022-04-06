# Getting Testy with Pester

## Presenter: Jason Ryberg
- GitHub [devopsjesus](https://github.com/devopsjesus)
- 7th year with MS Consulting
- Automation & efficiency enthusiast

---
## What is Pester (TL;DR version)
- [Pester Documentation](https://pester-docs.netlify.app/docs/quick-start)
- Pester is a testing and mocking framework for PowerShell
- Mocking allows for the replacement of the behavior of any command
- Tests go in *.Tests.ps1 files
- Can be run locally, but typically goes in an automated workflow as build criteria
- Basic Test structure
```PowerShell
Describe 'Unit Test' {

   BeforeAll {
      # Test setup (run the function)
   }

   Context 'Test Case' { # Not required

      It "Test Assertion" {
            # Should do something
      }
   }
}
```
---
## Running Pester Tests
- Simple vs Advanced vs Legacy interfaces
- Ignore the Simple & Legacy interfaces and just use the Pester Configuration object (advanced interface)!
- Easy to call
- Typically invoked recursively on a directory containing scripts or modules

```PowerShell
Invoke-Pester -Configuration $PesterConfig
```

---
### 🧑‍💻 Create Pester Configuration
```PowerShell
$PesterConfig = [PesterConfiguration]::Default # Init Config
$PesterConfig.Output.Verbosity = 'Detailed'    # Returns similar detailed output as v4
$PesterConfig.Run.Path = $env:USERPROFILE      # Set the run path for test discovery
$PesterConfig.Filter.ExcludeTag = 'broken'     # Exclude any tests tagged 'broken'
$PesterConfig
```
Output
```Text
Run          : Run configuration.
Filter       : Filter configuration
CodeCoverage : CodeCoverage configuration.
TestResult   : TestResult configuration.
Should       : Should configuration.
Debug        : Debug configuration for Pester. ⚠ Use at your own risk!
Output       : Output configuration
TestDrive    : TestDrive configuration.
TestRegistry : TestRegistry configuration.
```
---
### 🧑‍💻 View Configuration Attributes
```PowerShell
$PesterConfig.Run.Path
````
Output
```Text
Default Description                                                                                 Value                                                                                                                                        ------- -----------                                                                                 -----                                                                                                                                        {.}     Directories to be searched for tests, paths directly to test files, or combination of both. {C:\Users\el-user}                                                                                                                           
```
---
## Discovery vs Run
- Pester runs your test files in two phases: Discovery and Run.
- During discovery, it 'scans' your test files and discovers all the Pester blocks.
  - `It`, `Before*`, & `After*` blocks are saved as ScriptBlocks but **not** executed.
    - Exceptions are Before/AfterDiscovery blocks
  - `Describe` & `Context` blocks **are** executed
    - This is so that Pester can evaluate and save the `It` blocks
      - Builds the Tests using the `It` Names
      - Supports TestCases/ForEach parameters
- During run, all code within `It`, `BeforeAll`, `BeforeEach`, `AfterAll` or `AfterEach` blocks is executed.
- Put no code directly into `Describe`, `Context` or __ANYWHERE ELSE__ in your file.
- `InModuleScope`
   - Used for testing private functions in modules
   - Seems like it's still a work in progress for v5 (docs say don't wrap this block around `Describe` blocks, but I had to 🤷‍♂️)
---

## Code Coverage
- When can I stop writing tests without angering the PR Approvers?
- 100% is like the speed limit - it's the least you should do
- KISS principle is your friend - less logic in your code means fewer test cases, so fewer tests, which means more time for 🍺

To enable code coverage output, modify this Config attribute:
```PowerShell
$PesterConfig.CodeCoverage.Enabled = $true
```
---
## How to structure your tests: AAA
- Arrange
   - Setup prerequisites
   - Initialize parameter values
   - Create mocks
   - Import modules
   - Define data types
   - Etc, et al, ad infinitum
- Act
   - Execute the test by invoking the function
   - Capture the results for measurement/assertion
- Assert
   - Verify the results of the test are what you expected
   - Probably do some cleanup
---
# Insert Demo here
1. Reference Module file `Remove-Image` function to show what we're running and what we should expect
   1. Simple function to remove an image if it exists.
   1. Try/Catch is nice because instead of returning with null, the cmdlet will throw if no image is found (Could just bury the error with `-EA SilentlyContinue`, but we want the messaging - sometimes there's a typo in a variable pointing to the wrong resource group 🤷‍♂️)
   1. Basically two test cases
      - Image exists & we do nothing
      - Image does not exist and we do nothing
      - NOTE: Figured that out by reading my code, but that's why test-driven development is best, because you won't have to guess what your cases are afterwards :)
1. Two methods to invoke the test script - either run it directly or `Invoke-Pester`. Easier to run it locally while building, but must be certain to run as though part of CI/CD pipeline.
   1. Read through the output of the test run - does it make sense?
1. Analyze test file
   1. Explain scopes of the Pester blocks
      1. Describe the function
      1. Context is use case
      1. It is each test per case
         1. Can break these out as necessary, especially on longer functions
   1. Mocks are to keep the tests from actually doing anything IRL
      1. Essential for unit tests - instead of creating dependencies on actual Azure objects, we can pretend they exist. Save the real resources for the integration tests!
      1. Can filter Mock output based on parameter input
      1. Mocks can be very complex - see the Get-AzImage mock returning an error - this was necessary to keep Pester from throwing during the test (it was not trapping errors)
   1. Note the placement of the function invocation within the `Context`\\`BeforeAll` block
      1. In this test, the function can be run either within the `BeforeAll` block or `It` block - both have access to the `$params` hashtable since it was defined during the BeforeAll discovery phase
      1. I've placed this function run inside the BeforeAll block because you want your function to run before measuring the results with the `It` block
      1. This will vary based on the needs of the test (e.g. ForEach/TestCases)


      InModuleScope?