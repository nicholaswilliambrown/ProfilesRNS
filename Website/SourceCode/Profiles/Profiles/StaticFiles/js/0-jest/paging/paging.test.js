// object containing all the module.exports functions
const sumImport = require('../../paging/sum');

test('adds 1 + 2 to equal 3', () => {
  expect(sumImport.sum(1, 2)).toBe(3);
});
test('adds 1 + 2 to equal 3', () => {
  expect(sumImport.sum100(1, 2)).toBe(103);
});
