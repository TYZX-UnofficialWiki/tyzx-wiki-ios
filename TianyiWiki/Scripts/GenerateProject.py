import pathlib, hashlib, json
root=pathlib.Path(__file__).resolve().parents[2]
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
objects=[]
def obj(key,text): objects.append(f'{uid(key)} = {{ {text} }};'); return uid(key)
sources=[]; refs=[]
for p in sorted((root/'TianyiWiki/App').rglob('*.swift')):
    path=str(p.relative_to(root)); fid=obj(path, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = "<group>";')
    sources.append(obj('build'+path,f'isa = PBXBuildFile; fileRef = {fid};')); refs.append(fid)
asset=obj('assets','isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = TianyiWiki/Assets.xcassets; sourceTree = "<group>";')
assetbuild=obj('assetbuild',f'isa = PBXBuildFile; fileRef = {asset};')
localization=obj('localization','isa = PBXFileReference; lastKnownFileType = text.json; path = TianyiWiki/Resources/Localizations.json; sourceTree = \"<group>\";')
localizationbuild=obj('localizationbuild',f'isa = PBXBuildFile; fileRef = {localization};')
inforefs=[]
for language in ['zh-Hans','en','fr','ja','ko','lzh']:
    inforefs.append(obj('infolocal'+language,f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "{language}"; path = "TianyiWiki/Resources/{language}.lproj/InfoPlist.strings"; sourceTree = "<group>";'))
infovariant=obj('infovariant',f'isa = PBXVariantGroup; children = ({",".join(inforefs)},); name = InfoPlist.strings; sourceTree = "<group>";')
infobuild=obj('infobuild',f'isa = PBXBuildFile; fileRef = {infovariant};')
privacy=obj('privacy','isa = PBXFileReference; lastKnownFileType = text.xml; path = TianyiWiki/PrivacyInfo.xcprivacy; sourceTree = "<group>";')
privacybuild=obj('privacybuild',f'isa = PBXBuildFile; fileRef = {privacy};')
license=obj('license','isa = PBXFileReference; lastKnownFileType = text; path = TianyiWiki/LICENSE.txt; sourceTree = "<group>";')
licensebuild=obj('licensebuild',f'isa = PBXBuildFile; fileRef = {license};')
notices=obj('notices','isa = PBXFileReference; lastKnownFileType = text; path = TianyiWiki/THIRD_PARTY_NOTICES.txt; sourceTree = "<group>";')
noticesbuild=obj('noticesbuild',f'isa = PBXBuildFile; fileRef = {notices};')
product=obj('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = TianyiWiki.app; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
main=obj('main',f'isa = PBXGroup; children = ({",".join(refs+[asset,privacy,products])},); sourceTree = "<group>";')
src=obj('sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(sources)},); runOnlyForDeploymentPostprocessing = 0;')
res=obj('resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assetbuild},{privacybuild},{licensebuild},{noticesbuild},{localizationbuild},{infobuild},); runOnlyForDeploymentPostprocessing = 0;')
framework=obj('frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
for level in ['Debug','Release']:
    obj('project'+level, f'isa = XCBuildConfiguration; buildSettings = {{ SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; CLANG_ENABLE_MODULES = YES; SWIFT_VERSION = 6.0; ONLY_ACTIVE_ARCH = YES; }}; name = {level};')
    opt='-Onone' if level=='Debug' else '-O'
    obj('target'+level, f'''isa = XCBuildConfiguration; buildSettings = {{ PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = org.tyzx.TianyiWiki; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_FILE = TianyiWiki/Info.plist; INFOPLIST_KEY_CFBundleDisplayName = "天一维基"; INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.reference"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)","@executable_path/Frameworks",); SWIFT_VERSION = 6.0; ONLY_ACTIVE_ARCH = YES; SWIFT_STRICT_CONCURRENCY = complete; SWIFT_OPTIMIZATION_LEVEL = "{opt}"; MARKETING_VERSION = 0.2.0; CURRENT_PROJECT_VERSION = 1; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; LOCALIZATION_PREFERS_STRING_CATALOGS = YES; }}; name = {level};''')
for kind in ['project','target']:
    obj(kind+'config',f'isa = XCConfigurationList; buildConfigurations = ({uid(kind+"Debug")},{uid(kind+"Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target=obj('target',f'isa = PBXNativeTarget; buildConfigurationList = {uid("targetconfig")}; buildPhases = ({src},{framework},{res},); buildRules = (); dependencies = (); name = TianyiWiki; productName = TianyiWiki; productReference = {product}; productType = "com.apple.product-type.application";')
uitestref=obj('uitestref','isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TianyiWiki/Tests/TianyiWikiUITests.swift; sourceTree = "<group>";')
uitestbuild=obj('uitestbuild',f'isa = PBXBuildFile; fileRef = {uitestref};')
uitestproduct=obj('uitestproduct','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = TianyiWikiUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
uitestsrc=obj('uitestsrc',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({uitestbuild},); runOnlyForDeploymentPostprocessing = 0;')
proxy=obj('proxy',f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = TianyiWiki;')
dep=obj('dep',f'isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};')
for level in ['Debug','Release']:
    obj('ui'+level,f'isa = XCBuildConfiguration; buildSettings = {{ PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = org.tyzx.TianyiWikiUITests; GENERATE_INFOPLIST_FILE = YES; SWIFT_VERSION = 6.0; ONLY_ACTIVE_ARCH = YES; TEST_TARGET_NAME = TianyiWiki; TARGETED_DEVICE_FAMILY = "1,2"; }}; name = {level};')
uiconfig=obj('uiconfig',f'isa = XCConfigurationList; buildConfigurations = ({uid("uiDebug")},{uid("uiRelease")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
uitarget=obj('uitarget',f'isa = PBXNativeTarget; buildConfigurationList = {uiconfig}; buildPhases = ({uitestsrc},); buildRules = (); dependencies = ({dep},); name = TianyiWikiUITests; productName = TianyiWikiUITests; productReference = {uitestproduct}; productType = "com.apple.product-type.bundle.ui-testing";')
# Keep test sources visible in Xcode.
objects = [o.replace(f'children = ({product},);',f'children = ({product},{uitestproduct},);').replace(f'children = ({",".join(refs+[asset,privacy,products])},);',f'children = ({",".join(refs+[asset,privacy,products,uitestref])},);') for o in objects]
packageids=[]; productids=[]; frameworkids=[]
for name in ['WMFData','WMFComponents']:
    package=obj('package'+name,f'isa = XCLocalSwiftPackageReference; relativePath = {name};')
    dependency=obj('dependency'+name,f'isa = XCSwiftPackageProductDependency; package = {package}; productName = {name};')
    build=obj('link'+name,f'isa = PBXBuildFile; productRef = {dependency};')
    packageids.append(package); productids.append(dependency); frameworkids.append(build)
objects=[o.replace(f'{target} = {{ isa = PBXNativeTarget;',f'{target} = {{ isa = PBXNativeTarget; packageProductDependencies = ({",".join(productids)},);').replace(f'{framework} = {{ isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ();',f'{framework} = {{ isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({",".join(frameworkids)},);') for o in objects]
proj=obj('project',f'isa = PBXProject; packageReferences = ({",".join(packageids)},); attributes = {{ LastUpgradeCheck = 2700; }}; buildConfigurationList = {uid("projectconfig")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; knownRegions = ("zh-Hans",en,fr,ja,ko,lzh,Base); mainGroup = {main}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},{uitarget},);')
(root/'TianyiWiki.xcodeproj/xcshareddata/xcschemes').mkdir(parents=True,exist_ok=True)
(root/'TianyiWiki.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {proj}; }}\n')
(root/'TianyiWiki.xcodeproj/xcshareddata/xcschemes/TianyiWiki.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="TianyiWiki.app" BlueprintName="TianyiWiki" ReferencedContainer="container:TianyiWiki.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uitarget}" BuildableName="TianyiWikiUITests.xctest" BlueprintName="TianyiWikiUITests" ReferencedContainer="container:TianyiWiki.xcodeproj"/></TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="TianyiWiki.app" BlueprintName="TianyiWiki" ReferencedContainer="container:TianyiWiki.xcodeproj"/></BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
