export const SB_DIR = '/etc/sbproxy';
export const RUN_DIR = '/var/run/sbproxy';

export function isEmpty(v) {
	return !v || v === 'nil' || (type(v) in ['array', 'object'] && length(v) === 0);
};

export function strToBool(v) {
	return (v === '1') || (v === 'true') || null;
};

export function strToInt(v) {
	return !isEmpty(v) ? (int(v) || null) : null;
};

export function strToTime(v) {
	return !isEmpty(v) ? (v ~ /[smhd]$/ ? v : v + 's') : null;
};

export function removeBlankAttrs(res) {
	let content;

	if (type(res) === 'object') {
		content = {};
		map(keys(res), (k) => {
			if (type(res[k]) in ['array', 'object'])
				content[k] = removeBlankAttrs(res[k]);
			else if (res[k] !== null && res[k] !== '')
				content[k] = res[k];
		});
	} else if (type(res) === 'array') {
		content = [];
		map(res, (k) => {
			if (type(k) in ['array', 'object'])
				push(content, removeBlankAttrs(k));
			else if (k !== null && k !== '')
				push(content, k);
		});
	} else
		return res;

	return content;
};

export function decodeBase64Str(str) {
	if (isEmpty(str))
		return null;

	str = trim(str);
	str = replace(str, '_', '/');
	str = replace(str, '-', '+');

	const padding = length(str) % 4;
	if (padding)
		str = str + substr('====', padding);

	return b64dec(str);
};

export function parseURL(url) {
	if (type(url) !== 'string')
		return null;

	const services = {
		http: '80',
		https: '443'
	};

	const objurl = {};
	objurl.href = url;

	url = replace(url, /#(.+)$/, (_, val) => {
		objurl.hash = val;
		return '';
	});

	url = replace(url, /^(\w[A-Za-z0-9\+\-\.]+):/, (_, val) => {
		objurl.protocol = val;
		return '';
	});

	url = replace(url, /\?(.+)/, (_, val) => {
		objurl.search = val;
		let params = {};
		for (let kv in split(val, '&')) {
			let parts = split(kv, '=', 2);
			params[parts[0]] = parts[1];
		}
		objurl.searchParams = params;
		return '';
	});

	url = replace(url, /^\/\/([^\/]+)/, (_, val) => {
		val = replace(val, /^([^@]+)@/, (_, val2) => {
			objurl.userinfo = val2;
			return '';
		});

		val = replace(val, /:(\d+)$/, (_, val2) => {
			objurl.port = val2;
			return '';
		});

		objurl.hostname = replace(val, /^\[|\]$/g, '');
		return '';
	});

	objurl.pathname = url || '/';

	if (!objurl.protocol || !objurl.hostname)
		return null;

	if (objurl.userinfo) {
		objurl.userinfo = replace(objurl.userinfo, /:(.+)$/, (_, val) => {
			objurl.password = val;
			return '';
		});
		objurl.username = objurl.userinfo;
		delete objurl.userinfo;
	}

	if (!objurl.port)
		objurl.port = services[objurl.protocol];

	objurl.host = objurl.hostname + (objurl.port ? `:${objurl.port}` : '');
	objurl.origin = `${objurl.protocol}://${objurl.host}`;

	return objurl;
};
