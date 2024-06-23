// object containing all the module.exports functions
const pagingImport = require('../../paging/paging');

test('adds 1 + 2 to equal 3', () => {
  let page = new pagingImport.Paging();

  expect(page.sum(1, 2)).toBe(3);
});
