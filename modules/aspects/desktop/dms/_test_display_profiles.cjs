// Run with: node _test_display_profiles.cjs <path-to-DisplayConfigState.qml>
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const source = fs.readFileSync(process.argv[2], 'utf8');
const functions = [
    'getOutputIdentifier', 'profileKeyMatchesOutput', 'generateOutputsDataFromConfig',
    'getNiriSettingsFromConfig', 'backendSettingsFromConfig', 'ensureEnabledOutput',
    'applyConfigEntry',
].map(name => {
    const match = source.match(new RegExp('^    function ' + name + '\\([^]*?^    }', 'm'));
    assert(match, `Missing DMS function: ${name}`);
    return match[0];
}).join('\n');

const laptop = {make: 'BOE', model: 'NE135A1M-NY1', serial: null, modes: []};
const samsung = {make: 'Samsung Electric Company', model: 'U32R59x', serial: 'H4ZN200523', modes: []};
const samsungId = 'Samsung Electric Company U32R59x H4ZN200523';

function apply(outputs, profileOutputs, displayNameMode = 'system') {
    let written;
    let active;
    const context = vm.createContext({
        SettingsData: {displayNameMode},
        CompositorService: {compositor: 'niri', isNiri: true, isHyprland: false},
        SessionData: {setActiveDisplayProfile(_compositor, id) { active = id; }},
        WlrOutputService: {requestState() {}},
        publishActiveProfileModes() {},
        outputs,
        backendWriteOutputsConfig(data, settings, callback) {
            written = {data, settings};
            // Niri rejects empty output data, as generateOutputsConfig does.
            callback(Object.keys(data).length > 0);
        },
    });
    context.root = context;
    vm.runInContext(functions, context);
    context.applyConfigEntry({outputs: profileOutputs}, 'test-profile', '', false);
    return {written, active};
}

// Saved profiles omit make/model. Applying them must still reach the backend.
for (const [key, mode] of [['DP-3', 'system'], [samsungId, 'model']]) {
    const externalPort = mode === 'model' ? 'DP-7' : 'DP-3';
    const {written, active} = apply({'eDP-1': laptop, [externalPort]: samsung}, {
        [key]: {mode: '3840x2160@60.000', position: {x: 0, y: 0}, scale: 1},
        'eDP-1': {disabled: true, scale: 1.5},
    }, mode);
    assert.equal(Object.keys(written.data).length, 2, `${mode}: profile was discarded`);
    assert.equal(written.data[key].configured_mode, '3840x2160@60.000');
    assert.equal(written.settings['eDP-1'].disabled, true);
    assert.equal(active, 'test-profile');
}

const undocked = apply({'eDP-1': laptop}, {'eDP-1': {scale: 1.5, position: {x: 0, y: 0}}});
assert.equal(Object.keys(undocked.written.data).length, 1);
assert.equal(undocked.active, 'test-profile');

// Placeholder and disconnected outputs must not count as connected monitors.
for (const [outputs, key] of [
    [{'eDP-1': {make: '', model: ''}}, 'eDP-1'],
    [{'eDP-1': laptop}, 'DP-3'],
]) {
    const missing = apply(outputs, {[key]: {mode: '3840x2160@60.000'}});
    assert.equal(Object.keys(missing.written.data).length, 0);
    assert.equal(missing.active, undefined);
}
console.log('PASS: saved profiles apply; model matching survives port changes; absent outputs stay excluded');
