let t = TestRun.shared
runVersionCompareTests(t)
runSpacePaletteTests(t)
runFuzzyMatchTests(t)
runSpaceSettingsStoreTests(t)
runSpaceParserTests(t)
t.finish()
