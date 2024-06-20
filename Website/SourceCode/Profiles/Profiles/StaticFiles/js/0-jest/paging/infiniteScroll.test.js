// object containing all the module.exports functions
const sumImport = require('../../paging/infiniteScrollDiv');

test('adds 1 + 2 to equal 3', () => {
  expect(sumImport.sum100(1, 2)).toBe(103);
});
