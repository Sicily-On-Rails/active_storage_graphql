Per iniziare, configureremo il nostro server backend Rails per accettare richieste GraphQL. Presumendo che tu abbia già configurato un'applicazione Rails (altrimenti puoi trovare i dettagli qui), dobbiamo prima aggiungere GraphQL al nostro progetto.

```ruby
# Download the gem:
gem install graphql

# Setup with Rails:
rails generate graphql:install
```

Una volta installato, verrà creato una cartella app/graphql che contiene due directory, una per le mutazioni e una per i tipi. Ne parleremo meglio in seguito. Per prima cosa, creeremo il nostro modello in modo da avere qualcosa da aggiungere al database.

Stiamo per creare un semplice modello di evento con tre proprietà: nome, data e immagine. Poiché l'immagine sarà gestita da Active Storage, possiamo procedere e creare un modello con quei due campi per nome e data.

```ruby
# Generate Event model
rails generate model Event name:string start_date:date

# Update the database with new model
rails db:migrate
```

L'immagine sarà memorizzata nel database utilizzando uno strumento chiamato Active Storage. Active Storage ci permetterà di memorizzare allegati agli oggetti di Active Record e successivamente facilitare il caricamento di quei file nel cloud. A scopo di sviluppo, i file saranno semplicemente memorizzati in locale.

Per installare Active Storage, esegui prima:

```ruby
 Install Active Storage
rails active_storage:install

# Then run a db migration which will update the database with the Active Storage tables
rails db:migrate
```

Una volta che le tabelle sono state create, siamo pronti per modificare il nostro modello.

```ruby
# app/models/event.rb

class Event < ApplicationRecord
    has_one_attached :image
    
    validates :name, presence: true
    validates :start_date, presence: true
end
```

Nel nostro modello Event, abbiamo aggiunto tre nuove linee. Innanzitutto, vogliamo creare un allegato a un oggetto Active Storage. Per fare ciò, aggiungiamo il flag has_one_attached alla nostra proprietà image. Le due linee successive verificano semplicemente che il nome e la data di inizio devono essere presenti in tutte le voci degli eventi. Con il nostro modello in posizione, siamo ora pronti per aggiungere tipi e mutazioni al nostro backend GraphQL.

GraphQL query:
Come già accennato in precedenza, è stata aggiunta una nuova cartella al progetto quando abbiamo aggiunto GraphQL. È qui che faremo il resto del lavoro sul backend.

Per iniziare, creeremo un nuovo tipo che verrà utilizzato nelle richieste di query e mutazione. Di seguito è riportata una query GraphQL che recupererà un elenco di tutti i nostri eventi.

```ruby
query {
    events {
      id
      name
      startDate
      imageUrl
    }
}
```

Questa richiesta chiamata "events" restituirà l'id, il nome, la data di inizio e l'URL dell'immagine dal nostro tipo di evento. Per tradurre questo in Rails, dobbiamo aggiungere un nuovo tipo di query.

```ruby
#app/graphql/types/event_type.rb

module Types
  class Types::EventType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: false
    field :start_date, GraphQL::Types::ISO8601DateTime, null: false
    field :cover_image_url, String, null: true

  end
end
```

Ci sono alcune cose in gioco qui, quindi le esaminerò tutte. La prima cosa da notare è che stiamo chiamando questo tipo EventType, che deve corrispondere al nome del file. Successivamente, dichiariamo tutti i campi che possono essere utilizzati su questo tipo. Nel nostro caso, forniamo quattro campi: id, name, start_date e image_url. Nota che questi devono corrispondere nella query GraphQL con i campi in snake_case convertiti in camel case. Dopo i nomi, dichiariamo i tipi di campo. Per start_date vogliamo restituire una data nel formato ISO 8601, quindi utilizziamo il tipo integrato di GraphQL ISO8601DateTime. Infine, forniamo un valore booleano che indica se il campo può essere nullo o meno.

Potresti chiederti come EventType venga convertito nel nostro modello Event. Bene, una volta che aggiungiamo un nuovo campo a QueryType, forniremo una funzione per recuperare gli oggetti del modello e passarli a EventType. Questo espone quindi una proprietà dell'oggetto che possiamo utilizzare in EventType per modificare ciò che viene restituito dalla query. Questo è esattamente ciò che faremo per image_url. Poiché non memorizziamo image_url direttamente nel nostro modello Event, dobbiamo recuperarlo da Active Storage. Per fare ciò, sovrascriviamo image_url fornendo una nuova funzione.

```ruby
#app/graphql/types/event_type.rb

include(Rails.application.routes.url_helpers)

module Types
  class Types::EventType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :start_date, GraphQL::Types::ISO8601DateTime, null: false
    field :image_url, String, null: true

    def image_url
      if object.image.present?
        rails_blob_path(object.image, only_path: true)
      end
    end

  end
end
```

Nella nostra nuova funzione image_url, controlliamo prima se un'immagine è presente nel nostro evento. Se lo è, otteniamo il percorso all'immagine utilizzando una funzione url_helpers rails_blob_path che restituirà il percorso all'immagine. Nota che è anche necessario includere l'helper in alto.

Questo è tutto per il nostro EventType, ora dobbiamo aggiungere la query degli eventi all'interno di QueryType.

```ruby
#app/graphql/types/query_type.rb

module Types
  class QueryType < Types::BaseObject
    field :events, [EventType], null: false
 
     def all 
        Event
    end
  end
end
```

Il QueryType è il primo punto di accesso per la nostra richiesta GraphQL. Qui possiamo dichiarare tutti i diversi tipi di query desiderati. Nel nostro esempio, vogliamo solo restituire un elenco di eventi. Per questo, è sufficiente aggiungere un solo campo, che deve corrispondere al nome della query GraphQL. Nel nostro caso, l'abbiamo chiamato events. Forniamo anche un tipo per il nostro campo, che è un array di EventTypes, e anche un booleano che indica se può essere nullo o meno.

Infine, dobbiamo recuperare i modelli degli eventi per la nostra query. Per farlo, creiamo una funzione events e restituiamo tutti gli eventi nel nostro database. Poiché vogliamo anche i dati di Active Storage, dobbiamo recuperare tutti gli eventi con l'immagine allegata.

Congratulazioni, ora abbiamo una query completamente funzionante configurata in Rails utilizzando GraphQL.

Se eseguiamo questa query, vedremo un elenco di tutti gli eventi che abbiamo attualmente memorizzato nel database.

```ruby
query {
    events {
      id
      name
      startDate
      cover_imageUrl
    }
}
```

Un piccolo problema. Non abbiamo ancora voci nel database. Per creare nuove voci, dovremo creare una nuova mutazione GraphQL.

Mutazioni GraphQL:
Per aggiungere oggetti al nostro database, dovremo creare una mutazione GraphQL. Non solo, ma poiché stiamo caricando un'immagine, dovremo sfruttare alcune librerie di terze parti per aiutarci.

Per le richieste GraphQL, utilizzeremo uno strumento chiamato Apollo. Quando si tratta di query e richieste semplici, Apollo ha tutto ciò di cui abbiamo bisogno. Tuttavia, una volta che iniziamo a caricare file, abbiamo bisogno di un po' più di aiuto. Per caricare un'immagine, dovremo creare una richiesta multipart in modo da poter caricare il file insieme agli altri dati. Per fare ciò, dobbiamo utilizzare una gemma chiamata Apollo Upload Server. Quindi procediamo con l'installazione di questa gemma.


```ruby
# add to Gemfile
gem 'apollo_upload_server'
```
Una volta aggiunta la gemma, possiamo procedere e iniziare a creare la nostra mutazione.

```ruby
#app/graphql/mutations/add_event.rb

module Mutations
    class AddEvent < Mutations::BaseMutation
        argument :name, String, required: true
        argument :descritpion, String, required: true
        argument :start_date, String, required: true
        argument :image, ApolloUploadServer::Upload, required: true
    end
end
```
Iniziamo dichiarando gli argomenti che la nostra mutazione prenderà. Vogliamo caricare un nome e una data, entrambi come stringhe. Vogliamo anche un'immagine di tipo ApolloUploadServer::Upload. Questo tipo proviene dal server di caricamento di Apollo e farà tutto il lavoro di analisi della richiesta multipart e ci restituirà un file che possiamo utilizzare. Successivamente, dobbiamo aggiungere una funzione resolve per creare il nostro evento.

Dichiareremo anche i campi che possono essere restituiti nella nostra richiesta di mutazione GraphQL.

```ruby
#app/graphql/mutations/add_event.rb

…

field :event, Types::EventType, null: true
field :errors, [String], null: true    

def resolve(input)
    file = input[:image]
    blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
    )

    event = Event.new(
        name: input[:name],
        start_date: input[:start_date],
        image: blob
    )
    
    if event.save 
        { event: event } 
    else 
        { errors: event.errors.full_messages }
    end
end

…

```

Il primo campo sarà il nostro EventType che abbiamo creato in precedenza. Se la richiesta ha successo, verrà restituito un evento. Il secondo campo è il nostro errors, che restituirà eventuali errori generati dal salvataggio del nostro oggetto evento. Come per la query, questi due nomi di campo devono corrispondere ai nomi forniti nella mutazione. Esamineremo molto presto come appare la richiesta di mutazione grezza.

Infine, creiamo una funzione di risoluzione che riceve i dati dalla richiesta GraphQL e crea un nuovo oggetto evento. Per l'immagine, dobbiamo creare un allegato in modo che possa essere collegato al modello in Active Storage. Per creare l'allegato, utilizziamo ActiveStorage::Blob.create_and_upload! per generare un blob dal file che abbiamo importato e quindi lo passiamo al nostro evento. Una volta che l'oggetto è stato salvato, lo assegnamo al nostro campo evento in modo che possa essere restituito nella richiesta GraphQL.

Prima di poterlo testare, dobbiamo solo aggiungere un campo al nostro MutationType.

```ruby
#app/graphql/types/mutation_type.rb

module Types
  class MutationType < Types::BaseObject
    field :add_event, mutation: Mutations::AddEvent
  end
end
```

Come il nostro QueryType, questo sarà il nostro punto di accesso per la mutazione. Lo chiamiamo add_event e impostiamo il tipo sulla mutazione che abbiamo appena creato chiamata AddEvent.


Per far funzionare questa richiesta, dobbiamo inviare tre parti nei campi multipart. La prima è "operations", che è una stringa grezza della richiesta GraphQL.

```ruby
{
  "query": "mutation ($name: String!, $startDate: String!, $image: Upload!) { addEvent( input: { name: $name startDate: $startDate image: $image }) { event { id name startDate imageUrl } errors } }", "variables": { "name": "MultiTest2", "startDate": "13/04/2019", "image": null } 
}
```

In questa stringa, forniamo una query e alcune variabili. La parte di query è la mutazione GraphQL, che formattata appare così.

```ruby
mutation ($name: String!, $description: String!, $startDate: String!, $image: Upload!) {
    addEvent(
        input: {
           name: $name
           description: $description
           startDate: $startDate
           image: $image
        }
    ) { 
        event { 
            id
            name
            startDate
            imageUrl
        }
        errors
    }
}
```

Qui possiamo vedere più chiaramente esattamente ciò che dobbiamo passare. Prima diciamo che è una mutazione e passiamo i tre tipi di cui abbiamo bisogno. L'immagine è di tipo Upload, che corrisponderà al tipo Upload dal server di upload di Apollo. Successivamente, chiamiamo la mutazione add_event che abbiamo creato in precedenza. Ricorda che snake_case viene convertito in camel case in GraphQL, ecco perché sembra un po' diverso. Dopo di ciò, forniamo i valori di input, che nel nostro caso sono il nome, la data di inizio e l'immagine. Infine, forniamo i valori di ritorno, simili alla query.

La parte finale dell'operazione sono le variabili, che è un hash di tutte le variabili che stiamo includendo nella richiesta. Nota che l'immagine è impostata su null poiché sarà inclusa in una parte separata della richiesta.

La seconda parte della richiesta multipart è il campo map.


