const IPFS = require('ipfs-http-client');
const BS58 = require('bs58');
const ipfs = new IPFS({
  host: 'ipfs.infura.io',
  port: 5001,
  protocol: 'https'
});

export const setJSON = async (obj) => {
  return new Promise((resolve, reject) => {
    ipfs.add(obj, (err, result) => {
      if (err) {
        reject(err)
      } else {
        console.log(result);
        resolve(result);
      }
    });
  });
}

export const getJSON = async (hash) => {
  return new Promise((resolve, reject) => {
    ipfs.cat(hash, (err, result) => {
      if (err) {
        reject(err)
      } else {
        resolve(result)
      }
    });
  });
}

export const decodeIPFSHash = (hash) => {
  return "0x" + BS58.decode(hash).toString('hex').substr(4);
}

export const encodeIPFSHash = (hash) => {
  const multihashPrefix = "1220";
  return BS58.encode(Buffer.from((multihashPrefix + hash.substr(2)).toString('hex'), 'hex'));
}
