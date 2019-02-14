DROP INDEX index_customers_on_company_id_and_name ON customers;
CREATE INDEX index_customers_on_company_id_and_name ON customers (company_id, `name`);
CREATE UNIQUE INDEX index_customers_on_email ON customers (email);
