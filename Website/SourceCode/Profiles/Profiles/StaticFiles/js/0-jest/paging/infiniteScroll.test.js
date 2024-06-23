// object containing all the module.exports functions
const infiniteScrollImport = require('../../paging/infiniteScrollDiv');

test('adds 1 + 2 to equal 3', () => {
  let div = new infiniteScrollImport.InfiniteScrollDiv();
  expect(div.sum100(1, 2)).toBe(103);
});
