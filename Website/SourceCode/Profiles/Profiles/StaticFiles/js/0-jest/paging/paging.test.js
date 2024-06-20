// object containing all the module.exports functions
const sumImport = require('../../paging/paging');

test('adds 1 + 2 to equal 3', () => {
  expect(sumImport.sum(1, 2)).toBe(3);
});
