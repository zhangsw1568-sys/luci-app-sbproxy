'use strict';
'require uci';

return {
	nodeLabel: function(s) {
		let label = s.label || s['.name'];
		return '[' + (s.type || 'unknown') + '] ' + label;
	},
	dnsLabel: function(s) {
		return s.label || s['.name'];
	}
};
