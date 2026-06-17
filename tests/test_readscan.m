function tests = test_readscan
%TEST_READSCAN Regression tests for readscan YAML parsing.
%   Run with: runtests('test_readscan')
%
%   Covers the legacy "empty metadata block" case, where a scan.yaml writes
%       metadata:
%         []
%   which previously caused readscan to error.
%
%   See also readscan
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    % Put readscan.m (parent folder) and the fixtures on the path.
    thisDir = fileparts(mfilename('fullpath'));
    addpath(fileparts(thisDir));
    testCase.TestData.fixtureDir = fullfile(thisDir, 'fixtures');
end

function test_emptyMetadataDoesNotErrorAndParsesLaterBlocks(testCase)
    % Regression: an empty metadata block ("[]") must not error, must yield
    % empty metadata, and must NOT swallow the block that follows it (camera).
    scan = fullfile(testCase.TestData.fixtureDir, 'empty_metadata', 'scan.yaml');

    sdata = readscan(scan);

    verifyTrue(testCase, isempty(sdata.metadata), ...
        'metadata should be empty for a "[]" metadata block');
    verifyTrue(testCase, isfield(sdata, 'camera'), ...
        'camera block following an empty metadata block should still parse');
    verifyEqual(testCase, strtrim(sdata.camera.cameratype), 'Canon EDSDK', ...
        'camera.cameratype should be read from the block after metadata');
end

function test_populatedMetadataStillParses(testCase)
    % Guard: the empty-block fix must not break normal metadata parsing.
    scan = fullfile(testCase.TestData.fixtureDir, 'populated_metadata', 'scan.yaml');

    sdata = readscan(scan);

    verifyEqual(testCase, sdata.metadata.appname, 'GelSight Scan');
    verifyEqual(testCase, sdata.metadata.gelusecount, 7);
    verifyEqual(testCase, sdata.metadata.username, 'kimo');
    verifyTrue(testCase, isfield(sdata, 'camera'), ...
        'camera block following populated metadata should still parse');
end
