// object containing all the module.exports functions
const sumImport = require('../../paging/sum');

test('adds 2 + 1 to equal 3', () => {
  expect(sumImport.sum(2, 1)).toBe(3);
});
