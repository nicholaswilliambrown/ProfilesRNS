using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Net;

namespace ProfilesRNS_CallPRNSWebservice
{
    class CallPRNSWebservice
    {
        private string DataSource;
        private string Database;
        private string Username;
        private string Password;
        private string Job;
        private string BatchID;
        private int fails;
        private long success;
        private double failLimit;
        public CallPRNSWebservice(string dataSource, string database, string username, string password, string job)
        {
            this.DataSource = dataSource;
            this.Database = database;
            this.Username = username;
            this.Password = password;
            this.Job = job;
            Console.WriteLine("=========> Attempting job: " + job);
        }

        public void Run()
        {
            this.fails = 0;
            this.success = 0;

            List<Row> rows = GetRows();
            Console.WriteLine("=========> We have " + rows.Count + " row(s) to process");
            if (rows.Count > 0)
            {
                this.failLimit = .02 * rows.Count;
                this.BatchID = rows[0].BatchID;

                foreach(Row row in rows)
                {
                    try
                    {
                        CallWebservice(row);
                        this.success++;
                        if (this.success % 2 == 0)
                        {
                            Console.Write(".");
                            if (this.success % 500 == 0)
                            {
                                Console.Write(this.success + " good rows");
                            }
                        }
                    }
                    catch (Exception e) {
                        Console.WriteLine(e.ToString());
                        Console.WriteLine("\n=========> Row: \n      " + row.ToString());
                        this.fails++;
                        if (this.fails < this.failLimit)
                        {
                            continue;
                        }
                        else
                        {
                            Console.WriteLine("\n=========> Quitting due to " + this.fails + " row failures on the way to " + rows.Count + " rows total");
                            break;
                        }
                    }
                }
                Console.WriteLine("\n=========> Out of the set of " + rows.Count + " rows, " + this.success + " were processed successfully");
            }
        }

        private void CallWebservice(Row row)
        {
            AddLog(row, "StartService", "");

            WebServiceResponse response;
            if (row.HttpMethod == "GET")
            {
                response = HttpGet(row.URL);
            }
            else
            {
                response = HttpPost(row.URL, row.PostData, "text/xml");
            }

            if (response.Status == 0)
            {
                AddLog(row, "Error", response.Error);
                return;
            }

            AddLog(row, "EndService", "");

            ImportData(row, response.Status, response.Content);

            AddLog(row, "RowComplete", "");
        }

        private List<Row> GetRows()
        {
            List<Row> rows = new List<Row>();
            try
            {
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                builder.DataSource = DataSource;
                builder.UserID = Username;
                builder.Password = Password;
                builder.InitialCatalog = Database;

                using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    String sql = "exec [Profile.Import].[PRNSWebservice.GetPostData] @Job="+Job;

                    using (SqlCommand command = new SqlCommand(sql, connection))
                    {
                        using (SqlDataReader reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                rows.Add(new Row(logID: (Int64) reader.GetInt32(0), batchID: reader.GetString(1), rowID: reader.GetInt32(2), httpMethod: reader.GetString(3), url: reader.GetString(4), postData: reader.GetString(5)));
                            }
                        }
                    }
                }
            }
            catch (SqlException e)
            {
                Console.WriteLine(e.ToString());
            }
            return rows;
        }


        private void AddLog(Row row, string action, string actionText)
        {
            try
            {
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                builder.DataSource = DataSource;
                builder.UserID = Username;
                builder.Password = Password;
                builder.InitialCatalog = Database;

                using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    using (SqlCommand command = new SqlCommand())
                    {
                        command.Connection = connection;
                        command.CommandType = System.Data.CommandType.StoredProcedure;
                        command.CommandText = "[Profile.Import].[PRNSWebservice.AddLog]";
                        command.Parameters.AddWithValue("@logID", row.LogID);
                        command.Parameters.AddWithValue("@batchID", row.BatchID);
                        command.Parameters.AddWithValue("@rowID", row.RowID);
                        command.Parameters.AddWithValue("@Job", Job);
                        command.Parameters.AddWithValue("@action", action);
                        command.Parameters.AddWithValue("@actionText", actionText);
                        command.Parameters.Add("@newLogID", System.Data.SqlDbType.BigInt);
                        command.Parameters["@newLogID"].Direction = ParameterDirection.Output;

                        int i = command.ExecuteNonQuery();
                        Int64 l = Convert.ToInt64(command.Parameters["@newLogID"].Value);
                        if (l > 0) row.LogID = l;
                    }
                }
            }
            catch (SqlException e)
            {
                Console.WriteLine("\n=========> Failed to AddLog !!");
                Console.WriteLine(e.ToString());
            }
        }

        private void ImportData(Row row, int httpResponseCode, string data)
        {
            try
            {
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                builder.DataSource = DataSource;
                builder.UserID = Username;
                builder.Password = Password;
                builder.InitialCatalog = Database;

                using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    using (SqlCommand command = new SqlCommand())
                    {
                        command.Connection = connection;
                        command.CommandType = System.Data.CommandType.StoredProcedure;
                        command.CommandText = "[Profile.Import].[PRNSWebservice.ImportData]";
                        command.Parameters.AddWithValue("@Job", Job);
                        command.Parameters.AddWithValue("@batchID", row.BatchID);
                        command.Parameters.AddWithValue("@rowID", row.RowID);
                        command.Parameters.AddWithValue("@HttpResponseCode", httpResponseCode);
                        command.Parameters.AddWithValue("@logID", row.LogID);
                        command.Parameters.AddWithValue("@URL", row.URL);
                        command.Parameters.AddWithValue("@Data", data);

                        int i = command.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException e)
            {
                Console.WriteLine(e.ToString());
            }
        }


        private void CheckForErrors(string batchID)
        {
            try
            {
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                builder.DataSource = DataSource;
                builder.UserID = Username;
                builder.Password = Password;
                builder.InitialCatalog = Database;

                using (SqlConnection connection = new SqlConnection(builder.ConnectionString))
                {
                    connection.Open();

                    using (SqlCommand command = new SqlCommand())
                    {
                        command.Connection = connection;
                        command.CommandType = System.Data.CommandType.StoredProcedure;
                        command.CommandText = "[Profile.Import].[PRNSWebservice.CheckForErrors]";
                        command.Parameters.AddWithValue("@batchID", batchID);

                        int i = command.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException e)
            {
                Console.WriteLine(e.ToString());
            }
        }

        private WebServiceResponse HttpPost(string myUri, string myXml, string contentType)
        {
            WebServiceResponse response = new WebServiceResponse();

            Uri uri = new Uri(myUri);
            System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            WebRequest myRequest = WebRequest.Create(uri);
            myRequest.ContentType = contentType;
            //myRequest.ContentType = "application/x-www-form-urlencoded";
            myRequest.Method = "POST";

            byte[] bytes = Encoding.ASCII.GetBytes(myXml);
            System.IO.Stream os = null;

            string err = null;
            try
            { // send the Post
                myRequest.ContentLength = bytes.Length;   //Count bytes to send
                os = myRequest.GetRequestStream();
                os.Write(bytes, 0, bytes.Length);         //Send it
            }
            catch (WebException ex)
            {
                err = "Input=" + ex.Message;
            }
            finally
            {
                if (os != null)
                { os.Close(); }
            }

            try
            { // get the response
                WebResponse myResponse = myRequest.GetResponse();
                response.Status = 200;
                if (myResponse == null)
                { return null; }
                System.IO.StreamReader sr = new System.IO.StreamReader(myResponse.GetResponseStream());
               
                response.Content = sr.ReadToEnd().Trim();
            }
            catch (WebException ex)
            {
                response.Status = 0;
                response.Error = ex.Message;
            }
            return response;
        }

        private WebServiceResponse HttpGet(string myUri)
        {
            WebServiceResponse response = new WebServiceResponse();

            Uri uri = new Uri(myUri);
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            WebRequest myRequest = WebRequest.Create(uri);
            //myRequest.ContentType = contentType;
            //myRequest.ContentType = "application/x-www-form-urlencoded";
            myRequest.Method = "GET";

            //byte[] bytes = Encoding.ASCII.GetBytes(myXml);
            //Stream os = null;

            string err = null;

            try
            { // get the response
                WebResponse myResponse = myRequest.GetResponse();
                response.Status = 200;
                if (myResponse == null)
                { return null; }
                System.IO.StreamReader sr = new System.IO.StreamReader(myResponse.GetResponseStream());

                response.Content = sr.ReadToEnd().Trim();
            }
            catch (WebException ex)
            {
                response.Status = 0;
                response.Error = ex.Message;
            }
            return response;
        } 

        private class Row
        {
            public Row(Int64 logID, string batchID, int rowID, string httpMethod, string url, string postData)
            {
                LogID = logID;
                BatchID = batchID;
                RowID = rowID;
                HttpMethod = httpMethod;
                URL = url;
                PostData = postData;
            }

            public override string ToString()
            {
                return "LogID:" + LogID + "  RowID:" + RowID + "  URL:" + URL + "  PostData:"+ PostData;
            }

            public Int64 LogID;
            public string BatchID;
            public int RowID;
            public string HttpMethod;
            public string URL;
            public string PostData;
        }

        private class WebServiceResponse
        {
            public int Status;
            public string Content;
            public string Error;
        }


    }



}
