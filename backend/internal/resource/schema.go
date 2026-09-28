package resource

// Skema konten untuk website admin: form & tabel dibangun otomatis dari sini,
// jadi menambah konten di registry.go langsung muncul di admin tanpa ubah frontend.

// FieldSchema adalah deskripsi satu field untuk form admin.
type FieldSchema struct {
	Name      string     `json:"name"`
	Label     string     `json:"label"`
	Help      string     `json:"help,omitempty"`
	Type      string     `json:"type"`
	Input     Input      `json:"input"`
	Required  bool       `json:"required"`
	Nullable  bool       `json:"nullable"`
	MaxLength int        `json:"max_length,omitempty"`
	Options   []string   `json:"options,omitempty"`
	Min       *int       `json:"min,omitempty"`
	Max       *int       `json:"max,omitempty"`
	Pattern   string     `json:"pattern,omitempty"`
	Upload    string     `json:"upload,omitempty"`
	Image     *ImageSpec `json:"image,omitempty"`
	Section   string     `json:"section,omitempty"`
}

// ResourceSchema adalah deskripsi satu jenis konten untuk admin.
type ResourceSchema struct {
	Path        string        `json:"path"`
	Label       string        `json:"label"`
	Group       string        `json:"group"`
	Description string        `json:"description,omitempty"`
	Singleton   bool          `json:"singleton"`
	Sortable    bool          `json:"sortable"`
	UpsertKey   string        `json:"upsert_key,omitempty"`
	TitleField  string        `json:"title_field,omitempty"`
	Columns     []string      `json:"columns"`
	Filters     []string      `json:"filters"`
	Fields      []FieldSchema `json:"fields"`
}

var typeNames = map[FieldType]string{Text: "text", Int: "int", Bool: "bool", Timestamp: "timestamp"}

// Describe mengubah Resource menjadi skema untuk admin.
func Describe(r Resource) ResourceSchema {
	fields := make([]FieldSchema, 0, len(r.Fields))
	for _, f := range r.Fields {
		maxLen := 0
		if f.Type == Text {
			maxLen = f.MaxLen
			if maxLen == 0 {
				maxLen = defaultMaxLen
			}
		}
		fields = append(fields, FieldSchema{
			Name:      f.Name,
			Label:     f.Label,
			Help:      f.Help,
			Type:      typeNames[f.Type],
			Input:     f.input(),
			Required:  f.Required,
			Nullable:  !f.Required && !f.NotNull,
			MaxLength: maxLen,
			Options:   f.OneOf,
			Min:       f.Min,
			Max:       f.Max,
			Pattern:   f.Pattern,
			Upload:    f.Upload,
			Image:     f.Image,
			Section:   f.Section,
		})
	}
	columns := r.Columns
	if len(columns) == 0 {
		for _, f := range r.Fields[:min(3, len(r.Fields))] {
			columns = append(columns, f.Name)
		}
	}
	return ResourceSchema{
		Path:        r.Path,
		Label:       r.Label,
		Group:       r.Group,
		Description: r.Description,
		Singleton:   r.Singleton,
		Sortable:    r.Sortable(),
		UpsertKey:   r.UpsertKey,
		TitleField:  r.TitleField,
		Columns:     columns,
		Filters:     append([]string{}, r.Filters...),
		Fields:      fields,
	}
}

// input mengembalikan jenis kontrol form; bila kosong diturunkan dari tipe field.
func (f Field) input() Input {
	if f.Input != "" {
		return f.Input
	}
	switch {
	case len(f.OneOf) > 0:
		return InputSelect
	case f.Type == Int:
		return InputNumber
	case f.Type == Bool:
		return InputSwitch
	case f.Type == Timestamp:
		return InputDateTime
	case f.URL:
		return InputURL
	default:
		return InputText
	}
}
