package data;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class Handler {

    public static Holder holder = null;

    /**
     * Metodo que deserializa un json de un Holder con los datos de los juegos y lo almacena
     * @param json con los datos de los juegos
     * @throws JsonProcessingException
     */
    public static void deserializeGameData(String json) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true);
        holder = mapper.readValue(json, Holder.class);
    }

}
