using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Data.Analysis;


namespace Examples
{
    /// <summary>
    /// This example uses the Dataframe class from Microsoft.Data.Analysis
    /// and provides two functions to translate back and forth from ampl Dataframes.
    /// </summary>
    class MLDataFrame
    {
        /// <summary>
        /// Convert a ML DataFrame to an AMPL dataframe
        /// </summary>
        /// <param name="df">The ML Dataframe</param>
        /// <param name="nindices">The number of columns to be used as indices</param>
        /// <returns>An AMPL dataframe</returns>
        static ampl.DataFrame ToAMPLDataframe(DataFrame df, int nindices)
        {
            string[] columnHeaders = df.Columns.Select(column => column.Name).ToArray();
            ampl.DataFrame dfampl = new ampl.DataFrame(nindices, columnHeaders);
            foreach (var c in df.Columns)
            {
                if (c.DataType == typeof(double))
                {
                    var dd = c.Cast<double>().ToArray();
                    dfampl.SetColumn(c.Name, dd);
                }
                if (c.DataType == typeof(float))
                {
                    var dd = c.Cast<float>().Select(x => (double)x).ToArray();
                    dfampl.SetColumn(c.Name, dd);
                }
                if (c.DataType == typeof(int))
                {
                    var dd = c.Cast<int>().Select(x => (double)x).ToArray();
                    dfampl.SetColumn(c.Name, dd);
                }
                if (c.DataType == typeof(string))
                {
                    var dd = c.Cast<string>().ToArray();
                    dfampl.SetColumn(c.Name, dd);
                }
            }
            return dfampl;
        }
        /// <summary>
        /// Converts an ampl DataFrame to an ML one
        /// </summary>
        /// <param name="df">An ampl DataFrame</param>
        /// <returns>An ML Dataframe</returns>
        static DataFrame FromAMPLDataframe(ampl.DataFrame df)
        {
            string[] columnHeaders = df.GetHeaders();
            Microsoft.Data.Analysis.DataFrameColumn[] columns =
                    new Microsoft.Data.Analysis.DataFrameColumn[columnHeaders.Length];

            for (int i = 0; i < columnHeaders.Length; i++)
            {
                var c = df.GetColumn(columnHeaders[i]);
                if (c.Any(x => x.Type == Type.STRING))
                    columns[i] = new StringDataFrameColumn(columnHeaders[i], c.Select(x => x.Str));
                else
                    columns[i] = new PrimitiveDataFrameColumn<double>(columnHeaders[i], c.Select(x => x.Dbl));
            }
            DataFrame dfml = new DataFrame(columns);
            return dfml;
        }


        public static int Main(string[] args)
        {
            string modelDirectory = ((args != null) && (args.Length > 0)) ? args[0]
                : "../../models";
            string solver = ((args != null) && (args.Length > 1)) ? args[1] : null;

            // Define data path
            var dataPath = Path.Combine(modelDirectory, "diet/diet.csv");
            
            // Load some data into the ML data frame from CSV
            var dfFOODS = DataFrame.LoadCsv(dataPath);
            // Print some statistics
            Console.WriteLine(dfFOODS.Description());


            // Load some other data manually into an ML Dataframe
            string[] nutrients = { "A", "C", "B1", "B2", "NA", "CAL" };
            int[] nmin = { 700, 700, 700, 700, 0, 16000 };
            int[] nmax = { 20000, 20000, 20000, 20000, 50000, 24000 };
            
            DataFrame dfNutrients = new DataFrame(new Microsoft.Data.Analysis.DataFrameColumn[]  {
                    new StringDataFrameColumn("NUTR", nutrients),
                    new PrimitiveDataFrameColumn<int>("n_min", nmin),
                    new PrimitiveDataFrameColumn<int>("n_max", nmax)
            });


            // Last dataframe has  2 key columns, it is naturally represented as a 
            // 2d array, but we need to convert it to tabular format to fit into a 
            // dataframe
            string[] foods = {"BEEF", "CHK", "FISH", "HAM",
                    "MCH", "MTL", "SPG", "TUR" };
            int[,] amounts = {
            {  60,    8,   8,  40,   15,  70,   25,   60 },
            {  20,    0,  10,  40,   35,  30,   50,   20 },
            {  10,   20,  15,  35,   15,  15,   25,   15 },
            {  15,   20,  10,  10,   15,  15,   15,   10 },
            { 928, 2180, 945, 278, 1182, 896, 1329, 1397 },
            { 295,  770, 440, 430,  315, 400,  379,  450 } };
            string[] foodPairs = new string[foods.Length * nutrients.Length];
            string[] nutrientPairs= new string[foods.Length * nutrients.Length];
            int[] amountsLinear = new int[foods.Length * nutrients.Length];
            for (int i=0; i<foods.Length; i++)
            {
                for(int j=0; j<nutrients.Length; j++)
                {
                    foodPairs[i*nutrients.Length+j] = foods[i];
                    nutrientPairs[i * nutrients.Length + j] = nutrients[j];
                    amountsLinear[i * nutrients.Length + j] = amounts[j, i];
                }
            }
            DataFrame dfAmnt = new DataFrame(new Microsoft.Data.Analysis.DataFrameColumn[]  {
                    new StringDataFrameColumn("NUTR", nutrientPairs),
                    new StringDataFrameColumn("FOOD", foodPairs),
                    new PrimitiveDataFrameColumn<int>("amt", amountsLinear)
            });

            using (var ampl = new ampl.AMPL())
            {
                if (solver != null) ampl.SetOption("solver", solver);
                // Read the model file
                ampl.Read(modelDirectory + "/diet/diet.mod");
                // Set the data from the dataframes
                ampl.SetData(ToAMPLDataframe(dfFOODS, 1), "FOOD");
                ampl.SetData(ToAMPLDataframe(dfNutrients, 1), "NUTR");
                ampl.SetData(ToAMPLDataframe(dfAmnt, 2));
                // Solve the model
                ampl.Solve();

                // Get data from AMPL and convert it into an ML dataframe
                var c = FromAMPLDataframe(ampl.GetData("Buy"));

                // Print out variable ordered by value
                Console.WriteLine(c.OrderBy("Buy"));

            }
            return 0;
        }



    }
}
