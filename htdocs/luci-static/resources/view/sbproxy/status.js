'use strict';
'require fs';
'require rpc';
'require view';

var callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

return view.extend({
	load: function() {
		return Promise.all([
			fs.read_direct('/var/run/sbproxy/sbproxy.log', 'text').catch(function(){ return ''; }),
			callServiceList('sbproxy').catch(function(){ return {}; })
		]);
	},
	render: function(data) {
		let log = data[0] || '';
		let running = false;
		try {
			running = data[1]['sbproxy']['instances']['instance1']['running'];
		} catch (e) {}

		return E('div', { class: 'cbi-map' }, [
			E('h2', _('SBProxy Status')),
			E('p', running ? _('Service is running.') : _('Service is not running.')),
			E('p', _('Config path: /var/run/sbproxy/sing-box.json')),
			E('p', _('Clash UI path (if enabled): http://<router-ip>:9090/ui')),
			E('h3', _('Recent Log')),
			E('pre', { style: 'white-space: pre-wrap;' }, log || _('No log yet.'))
		]);
	}
});
